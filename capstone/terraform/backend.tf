terraform {
  backend "s3" {
    bucket       = "kijaniosk-tfstate-545572979505"
    key          = "capstone/track-a/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
