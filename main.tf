# PreRequirements:
# - Create KeyPair
# - Install terraform, and run `terraform init`
#
# Example:
# ```sh
# terraform apply -var "rds_master_user_password=foo"
# ```

# Syntax: https://www.terraform.io/docs/configuration/index.html
variable "key_name" {
  type    = string
  default = "websys2023"
}

variable "rds_master_user_password" {
  type    = string
  default = "0d986a1e36e91662de6186e66030a6e5e470039e"
}

provider "aws" {
  # profile = "default"
  region = "ap-northeast-1"
  # access_key = "" # set profile. or use env AWS_ACCESS_KEY_ID
  # secret_key = "" # set profile. or use env AWS_SECRET_ACCESS_KEY
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_groups" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  aws_security_group_default_id = data.aws_security_groups.default.ids[0]
}

resource "aws_security_group_rule" "allow_from_uec" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["130.153.0.0/16"]
  security_group_id = local.aws_security_group_default_id
  description       = "SSH from UEC"
}

## EC2
data "aws_kms_alias" "ebs" {
  name = "alias/aws/ebs"
}

data "aws_ssm_parameter" "al2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "web" {
  # https://www.terraform.io/docs/providers/aws/r/instance.html
  ami                    = data.aws_ssm_parameter.al2_ami.value
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [local.aws_security_group_default_id]
  root_block_device {
    delete_on_termination = true
    volume_size           = 8
    volume_type           = "gp2"
    encrypted             = true
    kms_key_id            = data.aws_kms_alias.ebs.target_key_arn
  }
}

## RDS
resource "aws_db_instance" "db" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.32"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = var.rds_master_user_password
  identifier             = "db-instance-1"
  vpc_security_group_ids = [local.aws_security_group_default_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}
