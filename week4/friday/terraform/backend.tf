terraform {
  # Remote state on S3 with DynamoDB-based state locking (cloud path).
  # The bucket and lock table are created once by scripts/bootstrap-backend.sh
  # because Terraform cannot manage the backend that stores its own state.
  backend "s3" {
    bucket       = "kijaniosk-tfstate-545572979505"
    key          = "week4/friday/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
