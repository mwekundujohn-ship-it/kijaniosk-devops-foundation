variable "name" {
  description = "Name of the server instance (for example kijaniosk-api)."
  type        = string
}

variable "role" {
  description = "Role of the server: api, payments or logs."
  type        = string
}

variable "app_port" {
  description = "Application port the server listens on."
  type        = number
}

variable "ami_id" {
  description = "AMI id resolved by the caller (never hardcoded here)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name used for SSH."
  type        = string
}

variable "subnet_id" {
  description = "Subnet the instance is launched into."
  type        = string
}

variable "vpc_id" {
  description = "VPC the security group belongs to."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR allowed to reach the application port."
  type        = string
}

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH (the operator's public IP)."
  type        = string
}

variable "tags" {
  description = "Extra tags applied to the instance and security group."
  type        = map(string)
  default     = {}
}
