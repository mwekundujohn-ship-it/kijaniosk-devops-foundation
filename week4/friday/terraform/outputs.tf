# Public IPs, keyed by server name - consumed by pipeline.sh to build the inventory.
output "server_ips" {
  description = "Public IP of every KijaniKiosk server, keyed by server name."
  value       = { for name, server in module.app_server : name => server.public_ip }
}

# Flat outputs so `terraform output -raw <name>` works in pipeline.sh.
output "api_server_ip" {
  description = "Public IP of the API server."
  value       = module.app_server["api"].public_ip
}

output "payments_server_ip" {
  description = "Public IP of the payments server."
  value       = module.app_server["payments"].public_ip
}

output "logs_server_ip" {
  description = "Public IP of the logs server."
  value       = module.app_server["logs"].public_ip
}

# Copy-paste SSH commands for the operators.
output "ssh_commands" {
  description = "Ready-to-paste SSH command per server."
  value = {
    for name, server in module.app_server :
    name => "ssh -i ${var.ssh_key_path} ubuntu@${server.public_ip}"
  }
}
