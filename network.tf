resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

# Adopt default existing security group for the VPC
# and declare no rules to overwrite the default rules 
# which allow all outbound traffic and inbound traffic
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main

  tags = {
    Name = "${local.name}-default-sg-DO-NOT-USE"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-igw"
  }
}
