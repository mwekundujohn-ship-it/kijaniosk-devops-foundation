variable "aws_region" {
  description = "AWS region the KijaniKiosk staging servers are provisioned in."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type used for every KijaniKiosk application server."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair (already imported) used for SSH access."
  type        = string
}

variable "admin_cidr" {
  description = "CIDR allowed to reach the servers on SSH (the operator's public IP)."
  type        = string
}

variable "ssh_key_path" {
  description = "Local path to the private key matching key_name, surfaced in the SSH outputs."
  type        = string
}

variable "servers" {
  description = "Map of KijaniKiosk servers to provision. Keyed by role; consumed with for_each."
  type = map(object({
    role     = string
    app_port = number
  }))
  default = {
    api = {
      role     = "api"
      app_port = 3000
    }
    payments = {
      role     = "payments"
      app_port = 3001
    }
    logs = {
      role     = "logs"
      app_port = 3002
    }
  }
}
