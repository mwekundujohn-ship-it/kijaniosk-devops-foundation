provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "kijaniosk"
      ManagedBy = "terraform"
      Capstone  = "track-a"
    }
  }
}

provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = var.kube_context
}
