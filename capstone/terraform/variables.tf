variable "aws_region" {
  description = "AWS region for the receipts bucket."
  type        = string
  default     = "us-east-1"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig used by the Kubernetes provider."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubeconfig context for the target cluster."
  type        = string
  default     = "minikube"
}

variable "staging_namespace" {
  description = "Namespace used for the staging promotion target."
  type        = string
  default     = "kijani-staging"
}

variable "production_namespace" {
  description = "Namespace used for the production promotion target."
  type        = string
  default     = "kijani-production"
}

variable "receipts_bucket_prefix" {
  description = "Prefix for the per-environment Week 10 receipts buckets."
  type        = string
  default     = "kk-payments-receipts"
}
