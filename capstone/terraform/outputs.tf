output "staging_namespace" {
  description = "Staging namespace created by Terraform."
  value       = kubernetes_namespace_v1.staging.metadata[0].name
}

output "production_namespace" {
  description = "Production namespace created by Terraform."
  value       = kubernetes_namespace_v1.production.metadata[0].name
}

output "staging_receipts_bucket" {
  description = "S3 bucket reserved for staging Week 10 receipts."
  value       = aws_s3_bucket.receipts["staging"].bucket
}

output "production_receipts_bucket" {
  description = "S3 bucket reserved for production Week 10 receipts."
  value       = aws_s3_bucket.receipts["production"].bucket
}

output "receipts_bucket_arns" {
  description = "ARNs of the per-environment receipts buckets."
  value       = { for environment, bucket in aws_s3_bucket.receipts : environment => bucket.arn }
}

output "kube_context" {
  description = "Kubeconfig context targeted by the Kubernetes provider."
  value       = var.kube_context
}
