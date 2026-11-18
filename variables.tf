variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "short name used in resource names and tags"
  type        = string
  default     = "cloud-journal-api"
}

variable "environment" {
  description = "environment name used in resource names and tags"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "vpc_cidr" {
  description = "IP range for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block. eg 10.0.0.0/16"
  }
}

variable "instance_type" {
  description = "EC2 Instance type for the API. t4g = ARM(Graviton)"
  type        = string
  # default     = "t4g.micro" arch might cause problems
  default = "t3.micro"
}

variable "app_port" {
  description = "Port the API listens on for Cloudfront"
  type        = number
  default     = 8000
}

variable "admin_ssh_cidrs" {
  description = "IPs allowed to ssh into instance"
  type        = list(string)
  default     = []
  # default = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.admin_ssh_cidrs : can(cidrhost(c, 0)) && c != "0.0.0.0/0"])
    error_message = "Each CIDR in admin_ssh_cidrs must be a valid IP address range, and not 0.0.0.0/0"
  }
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_engine_version" {
  type    = string
  default = "17"
}

variable "db_name" {
  type    = string
  default = "journaldb"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}
