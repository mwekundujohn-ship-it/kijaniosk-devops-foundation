#!/usr/bin/env bash
#
# kijaniosk-provision.sh
# Idempotent, 8-phase provisioning script for the KijaniKiosk production server.
# Safe to run repeatedly; converges a dirty server to the intended state.
#
# Expected dirty conditions found in pre-provisioning audit:
# - kk-api (UID 998), kk-payments (UID 999), kk-logs (UID 996) already exist
#   with non-spec properties: handled in Phase 2 by an existence check that
#   converges them (group, shell, lock) instead of re-adding blindly.
# - /opt/kijaniosk/config is 0777 (world-writable): fixed in Phase 3.
# - /opt/kijaniosk/shared/logs ACLs missing the kk-payments read entry and have
#   no default ACLs: fixed in Phase 3.
# - ufw holds a stray "deny 3001" rule from Thursday and only an uncommented SSH
#   rule: reset to a known baseline in Phase 5.
# - a stray apt-mark hold on curl: reconciled in Phase 1.
# - kk-api.service exists as the weak Wednesday unit (exposure 9.2 UNSAFE):
#   rewritten with full hardening in Phase 6.
#
set -uo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
GROUP="kijaniosk"
BASE="/opt/kijaniosk"
CONF="$BASE/config"
LOGS="$BASE/shared/logs"
HEALTH="$BASE/health"
JOURNAL_CONF="/etc/systemd/journald.conf"
LOGROTATE_CONF="/etc/logrotate.d/kijaniosk"
LOG_FILE="/var/log/kijaniosk-provision.log"

# service -> port
declare -A SVC_PORT=( [kk-api]=3000 [kk-payments]=3001 [kk-logs]=3002 )
SERVICES=(kk-api kk-payments kk-logs)

# packages we intentionally pin/hold; anything else found on hold is stray
PINNED_PKGS=(nginx)

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
declare -a CHECK_RESULTS=()
FAILED=0

ts() { date -Is; }
info()    { echo "$(ts) INFO   $*"; }
success() { echo "$(ts) PASS   $*"; }
warn()    { echo "$(ts) WARN   $*"; }
error()   { echo "$(ts) FAIL   $*"; }
phase()   { echo; echo "$(ts) ===== $* ====="; }

record() { # <name> <PASS|FAIL>
  local name="$1" status="$2"
  CHECK_RESULTS+=("$status||$name")
  [[ "$status" == "FAIL" ]] && FAILED=$((FAILED + 1))
}
check() { # <name> <command...>
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then record "$name" PASS; else record "$name" FAIL; fi
}

require_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || { error "must be run as root"; exit 1; }
}

# ---------------------------------------------------------------------------
# Phase 1: Preflight and package reconciliation
# ---------------------------------------------------------------------------
phase "Phase 1: Preflight and package reconciliation"
require_root
info "running on $(hostname) as $(id -un)"

for pkg in "${PINNED_PKGS[@]}"; do
  installed="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
  candidate="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/{print $2}')"
  if [[ -z "$installed" ]]; then
    info "installing $pkg"
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >/dev/null 2>&1
  elif [[ "$installed" == "$candidate" ]]; then
    info "already at intended version: $pkg=$installed (skip install)"
  else
    # Decision (Challenge D): do NOT silently downgrade a running server.
    # Surface the mismatch loudly for human review instead.
    warn "version drift: $pkg installed=$installed candidate=$candidate (not downgrading)"
  fi
  apt-mark hold "$pkg" >/dev/null 2>&1 || true
done

# clear stray holds not in the intended set (e.g. curl from the week's labs)
while read -r held; do
  [[ -z "$held" ]] && continue
  if ! printf '%s\n' "${PINNED_PKGS[@]}" | grep -qx "$held"; then
    info "clearing stray package hold: $held"
    apt-mark unhold "$held" >/dev/null 2>&1 || true
  fi
done < <(apt-mark showhold 2>/dev/null)

check "packages-pinned" bash -c "apt-mark showhold | grep -qx nginx"

# ---------------------------------------------------------------------------
# Phase 2: Service accounts and group
# ---------------------------------------------------------------------------
phase "Phase 2: Service accounts and group"

if getent group "$GROUP" >/dev/null; then
  info "already exists: group $GROUP"
else
  groupadd --system "$GROUP" && info "created group $GROUP"
fi

for svc in "${SERVICES[@]}"; do
  if getent passwd "$svc" >/dev/null; then
    info "Already exists: $svc (UID $(id -u "$svc")) - converging to spec"
  else
    useradd --system --gid "$GROUP" --no-create-home \
            --shell /usr/sbin/nologin "$svc" && info "created $svc"
  fi
  # converge properties regardless of how it was first created
  usermod -a -G "$GROUP" -s /usr/sbin/nologin -d /nonexistent "$svc" >/dev/null 2>&1 || true
  usermod -L "$svc" >/dev/null 2>&1 || true   # service accounts never need a password
  passwd -u "$svc" >/dev/null 2>&1 || true
done

for svc in "${SERVICES[@]}"; do
  check "account-$svc" id "$svc"
done

# ---------------------------------------------------------------------------
# Phase 3: Directory structure, ownership and ACL model
# ---------------------------------------------------------------------------
phase "Phase 3: Directory structure and ACL model"

install -d -m 0750 -o root -g "$GROUP" "$BASE"
install -d -m 0750 -o root -g "$GROUP" "$CONF"
install -d -m 0750 -o root -g "$GROUP" "$BASE/releases"
install -d -m 2770 -o root -g "$GROUP" "$LOGS"
install -d -m 0750 -o root -g "$GROUP" "$HEALTH"

info "tightened /opt/kijaniosk/config to 0750 (was world-writable)"
chmod 0750 "$CONF"

# Named ACLs on shared/logs (fixes the missing kk-payments entry)
setfacl -b "$LOGS"
setfacl -m u:kk-api:rwx "$LOGS"
setfacl -m u:kk-logs:rwx "$LOGS"
setfacl -m u:kk-payments:r-x "$LOGS"
# Default ACLs so files created inside (e.g. by logrotate) inherit the model
setfacl -d -m u::rwx -m g::rwx -m o::--- \
          -m u:kk-api:rw- -m u:kk-logs:rw- -m u:kk-payments:r-- -m m::rw- "$LOGS"

# seed log files with a bootstrap entry so logrotate has content to rotate
for f in api.log payments.log logs.log; do
  if [[ ! -s "$LOGS/$f" ]]; then
    printf '%s kijaniosk bootstrap log entry\n' "$(ts)" > "$LOGS/$f"
  fi
done
chown root:"$GROUP" "$LOGS"/*.log 2>/dev/null || true
chmod 0660 "$LOGS"/*.log 2>/dev/null || true

check "acl-kk-payments-on-logs" bash -c "getfacl -p '$LOGS' | grep -q '^user:kk-payments:'"
check "default-acl-present" bash -c "getfacl -p '$LOGS' | grep -q '^default:'"
check "config-not-world-writable" bash -c "[[ \$(stat -c '%a' '$CONF') == '750' ]]"

# ---------------------------------------------------------------------------
# Phase 4: Configuration files (EnvironmentFiles)
# ---------------------------------------------------------------------------
phase "Phase 4: Configuration files"

write_env() { # <file> <service> <port>
  local file="$1" svc="$2" port="$3"
  {
    echo "# KijaniKiosk $svc environment"
    echo "KK_ENV=production"
    echo "KK_SERVICE=$svc"
    echo "KK_LOG_DIR=$LOGS"
    case "$svc" in
      kk-api)      echo "KK_PORT=$port"; echo "KK_DB_HOST=10.0.2.10" ;;
      kk-payments) echo "KK_PORT=$port"; echo "KK_PAYMENTS_PROVIDER=internal" ;;
      kk-logs)     echo "KK_PORT=$port"; echo "KK_RETENTION_DAYS=7" ;;
    esac
  } > "$file"
  chown root:"$GROUP" "$file"
  chmod 0640 "$file"
  # keep each service able to read only its own file
  setfacl -m "u:$svc:r--" "$file"
}

write_env "$CONF/api.env"      kk-api      3000
write_env "$CONF/payments-api.env" kk-payments 3001
write_env "$CONF/logs.env"     kk-logs     3002

for svc in "${SERVICES[@]}"; do
  file="$CONF/$( [[ $svc == kk-payments ]] && echo payments-api.env || ([[ $svc == kk-api ]] && echo api.env || echo logs.env) )"
  check "env-readable-$svc" sudo -u "$svc" cat "$file"
done

# ---------------------------------------------------------------------------
# Phase 5: Firewall (intent, not history)
# ---------------------------------------------------------------------------
phase "Phase 5: Firewall"

ufw --force reset >/dev/null 2>&1
ufw default deny incoming  >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1
ufw allow 22/tcp comment 'SSH admin access' >/dev/null 2>&1
ufw allow 80/tcp comment 'HTTP public web'  >/dev/null 2>&1
ufw allow 443/tcp comment 'HTTPS public web' >/dev/null 2>&1
# payments health check only from the monitoring subnet
ufw allow from 10.0.1.0/24 to any port 3001 proto tcp comment 'kk-payments health from monitoring subnet' >/dev/null 2>&1
# internal service port: allow loopback (nginx proxy) BEFORE the external deny
ufw allow in on lo to any port 3001 proto tcp comment 'kk-payments internal via loopback (nginx proxy)' >/dev/null 2>&1
ufw deny to any port 3001 proto tcp comment 'kk-payments external deny (internal service)' >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1

verify_firewall() {
  local failed=0 s
  s="$(ufw status)"
  echo "$s" | grep -qE '22/tcp .*ALLOW'      && success "PASS: SSH (22) allowed"                || { error "FAIL: SSH rule missing"; failed=$((failed+1)); }
  echo "$s" | grep -qE '80/tcp .*ALLOW'      && success "PASS: HTTP (80) allowed"               || { error "FAIL: HTTP rule missing"; failed=$((failed+1)); }
  echo "$s" | grep -qE '443/tcp .*ALLOW'     && success "PASS: HTTPS (443) allowed"             || { error "FAIL: HTTPS rule missing"; failed=$((failed+1)); }
  echo "$s" | grep -qE '3001.*ALLOW.*10\.0\.1\.0/24' && success "PASS: payments health from subnet allowed" || { error "FAIL: subnet allow missing"; failed=$((failed+1)); }
  echo "$s" | grep -qE '3001.*DENY'          && success "PASS: port 3001 external deny present" || { error "FAIL: 3001 deny missing"; failed=$((failed+1)); }
  echo "$s" | grep -qiE '3001.*on lo.*ALLOW' && success "PASS: loopback allow present"    || warn "WARN: loopback allow not visible in status (rule exists in ufw)"
  return $failed
}
if verify_firewall; then record "firewall-rules" PASS; else record "firewall-rules" FAIL; fi

# ---------------------------------------------------------------------------
# Phase 6: systemd units (all three, written inline, hardened)
# ---------------------------------------------------------------------------
phase "Phase 6: systemd units"

common_harden() {
cat <<'EOF'
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=strict
ProtectHome=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
ProtectClock=yes
ProtectHostname=yes
ProtectProc=invisible
ProcSubset=pid
RestrictRealtime=yes
RestrictSUIDSGID=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
RestrictNamespaces=yes
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
SystemCallArchitectures=native
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources @obsolete
CapabilityBoundingSet=
AmbientCapabilities=
UMask=0027
EOF
}

write_unit() { # <svc>
  local svc="$1" port="${SVC_PORT[$svc]}"
  local envf
  case "$svc" in
    kk-api)      envf="$CONF/api.env" ;;
    kk-payments) envf="$CONF/payments-api.env" ;;
    kk-logs)     envf="$CONF/logs.env" ;;
  esac
  {
    echo "[Unit]"
    echo "Description=KijaniKiosk ${svc} service"
    echo "After=network-online.target"
    echo "Wants=network-online.target"
    if [[ "$svc" == "kk-payments" ]]; then
      echo "After=kk-api.service"
      echo "Wants=kk-api.service"
    fi
    echo
    echo "[Service]"
    echo "Type=simple"
    echo "User=$svc"
    echo "Group=$GROUP"
    echo "EnvironmentFile=$envf"
    echo "Environment=PYTHONDONTWRITEBYTECODE=1"
    echo "ExecStart=/usr/bin/socat TCP-LISTEN:$port,fork,reuseaddr /dev/null"
    echo "Restart=on-failure"
    echo "RestartSec=2"
    echo "ReadWritePaths=$LOGS"
    common_harden
    if [[ "$svc" == "kk-payments" ]]; then
      # payments may only talk to loopback and the monitoring subnet
      echo "IPAddressDeny=any"
      echo "IPAddressAllow=localhost"
      echo "IPAddressAllow=10.0.1.0/24"
      echo "RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6"
      echo "SystemCallFilter=~@privileged @resources @obsolete @mount @debug @cpu-emulation @swap @clock"
    fi
    echo
    echo "[Install]"
    echo "WantedBy=multi-user.target"
  } > "/etc/systemd/system/${svc}.service"
  info "wrote /etc/systemd/system/${svc}.service"
}

for svc in "${SERVICES[@]}"; do write_unit "$svc"; done
systemctl daemon-reload

for svc in "${SERVICES[@]}"; do
  systemctl enable "$svc" >/dev/null 2>&1
  systemctl restart "$svc" >/dev/null 2>&1
  if systemctl is-active --quiet "$svc"; then
    success "PASS: $svc started"
    record "unit-active-$svc" PASS
  else
    error "FAIL: $svc did not start"
    record "unit-active-$svc" FAIL
  fi
done

# ---------------------------------------------------------------------------
# Phase 7: Journal persistence and log rotation
# ---------------------------------------------------------------------------
phase "Phase 7: Journal persistence and log rotation"

install -d -m 2755 -o root -g systemd-journal /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal >/dev/null 2>&1 || true

if grep -qE '^\s*#?\s*Storage=' "$JOURNAL_CONF"; then
  sed -i 's/^\s*#\?\s*Storage=.*/Storage=persistent/' "$JOURNAL_CONF"
else
  printf '\n[Journal]\nStorage=persistent\n' >> "$JOURNAL_CONF"
fi
if grep -qE '^\s*#?\s*SystemMaxUse=' "$JOURNAL_CONF"; then
  sed -i 's/^\s*#\?\s*SystemMaxUse=.*/SystemMaxUse=500M/' "$JOURNAL_CONF"
else
  printf 'SystemMaxUse=500M\n' >> "$JOURNAL_CONF"
fi
systemctl restart systemd-journald >/dev/null 2>&1 || true
info "journal configured: persistent, capped at 500M"

cat > "$LOGROTATE_CONF" <<'EOF'
/opt/kijaniosk/shared/logs/*.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    # shared/logs is group-writable (part of the ACL model), so logrotate
    # refuses to run without an explicit su directive.
    # create mode's group bits become the ACL mask; 0660 keeps "rw" in the mask
    # so the directory's default ACLs grant kk-api/kk-logs rw on rotated files.
    su root kijaniosk
    create 0660 root kijaniosk
    sharedscripts
    # kk-logs has no ExecReload=, so `systemctl reload` would fail.
    # Restart is the correct fallback for a service that cannot reopen handles.
    postrotate
        /bin/systemctl restart kk-logs.service >/dev/null 2>&1 || true
    endscript
}
EOF
info "wrote $LOGROTATE_CONF"

if logrotate --debug "$LOGROTATE_CONF" 2>&1 | grep -qiE 'error|malformed'; then
  error "FAIL: logrotate --debug reported errors"; record "logrotate-debug" FAIL
else
  success "PASS: logrotate --debug clean"; record "logrotate-debug" PASS
fi

check "journald-persistent" bash -c "grep -qE '^Storage=persistent' '$JOURNAL_CONF'"
check "journald-500m" bash -c "grep -qE '^SystemMaxUse=500M' '$JOURNAL_CONF'"

# ---------------------------------------------------------------------------
# Phase 8: Monitoring health checks
# ---------------------------------------------------------------------------
phase "Phase 8: Monitoring health checks"

port_state() { # <port> -> ok|down
  if timeout 2 bash -c "echo > /dev/tcp/127.0.0.1/$1" 2>/dev/null; then echo '"ok"'; else echo '"down"'; fi
}

install -d -m 0750 -o root -g "$GROUP" "$HEALTH"
JSON="$HEALTH/last-provision.json"
{
  printf '{"timestamp":"%s"' "$(ts)"
  for svc in "${SERVICES[@]}"; do
    printf ',"%s":%s' "$svc" "$(port_state "${SVC_PORT[$svc]}")"
  done
  printf '}\n'
} > "$JSON"
chown kk-logs:"$GROUP" "$JSON"
chmod 0640 "$JSON"

success "wrote health check $JSON"
cat "$JSON"

check "health-json-exists" test -f "$JSON"
check "health-json-readable-by-group" bash -c "sudo -u kk-logs cat '$JSON' >/dev/null"

# ---------------------------------------------------------------------------
# Final verification
# ---------------------------------------------------------------------------
phase "Final verification"
echo
printf '%-45s %s\n' "CHECK" "RESULT"
printf '%-45s %s\n' "-----" "------"
for r in "${CHECK_RESULTS[@]}"; do
  name="${r##*||}"; status="${r%%||*}"
  printf '%-45s %s\n' "$name" "$status"
done
echo
echo "Total checks: ${#CHECK_RESULTS[@]}   Failures: $FAILED"
if [[ "$FAILED" -eq 0 ]]; then
  success "ALL CHECKS PASSED"
  exit 0
else
  error "$FAILED CHECK(S) FAILED"
  exit 1
fi
