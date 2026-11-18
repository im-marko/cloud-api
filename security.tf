data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_ec2_managed_prefix_list" "ec2_instance_connect" {
  name = "com.amazonaws.${var.aws_region}.ec2-instance-connect"
}

resource "aws_security_group" "api" {
  name        = "${local.name}-api-sg"
  description = "API instance: SSH access and outbound rules. DB trusts this SG."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name}-api-sg"
  }
}

resource "aws_security_group" "api_web" {
  name        = "${local.name}-api-web-sg"
  description = "API instance: app port from CloudFront only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name}-api-web-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "api_from_cloudfront" {
  security_group_id = aws_security_group.api_web.id
  description       = "App port from CloudFront only"
  ip_protocol       = "tcp"
  from_port         = var.app_port
  to_port           = var.app_port
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

resource "aws_vpc_security_group_ingress_rule" "api_ssh_instance_connect" {
  security_group_id = aws_security_group.api.id
  description       = "SSH from EC2 Instance Connect service"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  prefix_list_id    = data.aws_ec2_managed_prefix_list.ec2_instance_connect.id
}

resource "aws_vpc_security_group_ingress_rule" "api_ssh_admin" {
  for_each = toset(var.admin_ssh_cidrs)

  security_group_id = aws_security_group.api.id
  description       = "SSH with key pair from admin IP"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "api_https_out" {
  security_group_id = aws_security_group.api.id
  description       = "HTTPS out: AWS APIs (Secrets Manager), package repos"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "api_http_out" {
  security_group_id = aws_security_group.api.id
  description       = "HTTP out: Ubuntu apt mirrors"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "api_to_db" {
  security_group_id            = aws_security_group.api.id
  description                  = "PostgreSQL to the database only"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_security_group" "db" {
  name        = "${local.name}-db-sg"
  description = "RDS PostgreSQL: accepts connections from the API SG only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name}-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_api" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from API instances only"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.api.id
}
