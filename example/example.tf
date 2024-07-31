provider "aws" {
  region = "eu-west-1"
}

locals {
  environment = "app"
  label_order = ["name", "environment"]
}

module "vpc" {
  source      = "cypik/vpc/aws"
  version     = "1.0.1"
  name        = "app"
  environment = local.environment
  label_order = local.label_order
  cidr_block  = "172.16.0.0/16"
}

module "public_subnets" {
  source             = "cypik/subnet/aws"
  version            = "1.0.1"
  name               = "public-subnet"
  environment        = local.environment
  label_order        = local.label_order
  availability_zones = ["eu-west-1b", "eu-west-1c"]
  vpc_id             = module.vpc.id
  cidr_block         = module.vpc.vpc_cidr_block
  type               = "public"
  igw_id             = module.vpc.igw_id
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}

module "iam-role" {
  source             = "cypik/iam-role/aws"
  version            = "1.0.1"
  name               = "iam-role"
  environment        = local.environment
  label_order        = local.label_order
  assume_role_policy = data.aws_iam_policy_document.default.json
  policy_enabled     = true
  policy             = data.aws_iam_policy_document.iam-policy.json
}

data "aws_iam_policy_document" "default" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "iam-policy" {
  statement {
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
    "ssmmessages:OpenDataChannel"]
    effect    = "Allow"
    resources = ["*"]
  }
}

module "ec2" {
  source            = "./../"
  name              = "ec2"
  environment       = local.environment
  vpc_id            = module.vpc.id
  ssh_allowed_ip    = ["0.0.0.0/0"]
  ssh_allowed_ports = [22]

  ###allow ingress port and ip
  allow_ingress_port_ip = {
    "80"   = "0.0.0.0/0"
    "443"  = "0.0.0.0/0"
    "1149" = "0.0.0.0/0"
  }

  #Instance
  instance_count = 1
  ami            = "ami-0dd271720c1ba44f"
  instance_type  = "t2.micro"

  #Keypair
  public_key = "tmyQFspPKmaUW7DBMO+++3op32ybCEY+GeemdI6Zd28ZjgQUB1k= baldev@baldev"

  #Networking
  subnet_ids = tolist(module.public_subnets.public_subnet_id)

  #IAM
  iam_instance_profile = module.iam-role.name

  #Root Volume
  root_block_device = [
    {
      volume_type           = "gp2"
      volume_size           = 15
      delete_on_termination = true
    }
  ]

  #EBS Volume
  ebs_volume_enabled = true
  ebs_volume_type    = "gp2"
  ebs_volume_size    = 30

  #Tags
  instance_tags = { "snapshot" = true }
  #user data
  user_data = file("${path.module}/pritunl.sh")
}
