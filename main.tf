terraform {
  required_version = ">=1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  name    = "${var.project_name}-${var.environment}"
  is_prod = var.environment == "prod"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# output "availability_zones" {
# value = data.aws_availability_zones.available.names
# }

data "aws_ec2_instance_type_offerings" "api" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
}

locals {
  azs = slice(
    sort(setintersection(
      data.aws_availability_zones.available.names,
      data.aws_ec2_instance_type_offerings.api.locations
    )),
    0, 2
  )
}
