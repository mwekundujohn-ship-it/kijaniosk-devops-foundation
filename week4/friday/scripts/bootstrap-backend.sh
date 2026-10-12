#!/usr/bin/env bash
# Creates the S3 bucket, DynamoDB lock table and EC2 key pair that the
# Terraform remote backend depends on. Run once before `terraform init`.
#
# These resources are intentionally outside Terraform: the backend that stores
# Terraform's own state cannot be created by Terraform itself.
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="kijaniosk-tfstate-${ACCOUNT_ID}"
LOCK_TABLE="kijaniosk-tfstate-lock"
KEY_NAME="kijaniosk"
KEY_PATH="${HOME}/.ssh/kijaniosk_ed25519"
ADMIN_CIDR="${ADMIN_CIDR:-$(curl -s https://checkip.amazonaws.com)/32}"

echo ">> Backend bootstrap in ${AWS_REGION} (account ${ACCOUNT_ID})"
echo ">> Admin CIDR: ${ADMIN_CIDR}"

echo ">> S3 bucket ${BUCKET}"
if ! aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  aws s3api create-bucket --bucket "${BUCKET}" --region "${AWS_REGION}" >/dev/null
fi
aws s3api put-bucket-versioning --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "${BUCKET}" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo ">> DynamoDB lock table ${LOCK_TABLE}"
if ! aws dynamodb describe-table --table-name "${LOCK_TABLE}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  aws dynamodb create-table \
    --table-name "${LOCK_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${AWS_REGION}" >/dev/null
  aws dynamodb wait table-exists --table-name "${LOCK_TABLE}" --region "${AWS_REGION}"
fi

echo ">> SSH key pair ${KEY_NAME}"
[ -f "${KEY_PATH}" ] || ssh-keygen -t ed25519 -N '' -f "${KEY_PATH}" -C kijaniosk >/dev/null
if ! aws ec2 describe-key-pairs --key-names "${KEY_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  aws ec2 import-key-pair --key-name "${KEY_NAME}" \
    --public-key-material "fileb://${KEY_PATH}.pub" --region "${AWS_REGION}" >/dev/null
fi

echo ">> Done. Update terraform/terraform.tfvars admin_cidr to ${ADMIN_CIDR} if it changed."
