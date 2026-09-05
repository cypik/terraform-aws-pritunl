provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "app"
  label_order = ["name", "environment"]
}

module "vpc" {
  source      = "cypik/vpc/aws"
  version     = "1.0.5"
  name        = "app11"
  environment = local.environment
  label_order = local.label_order
  cidr_block  = "172.16.0.0/16"
}

module "public_subnets" {
  source             = "cypik/subnet/aws"
  version            = "1.0.7"
  name               = "public-subnet"
  environment        = local.environment
  label_order        = local.label_order
  availability_zones = ["us-east-1b", "us-east-1c"]
  vpc_id             = module.vpc.vpc_id
  cidr_block         = module.vpc.vpc_cidr_block
  type               = "public"
  igw_id             = module.vpc.igw_id
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}

module "iam-role" {
  source             = "cypik/iam-role/aws"
  version            = "1.0.4"
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

module "pritunl" {
  source            = "./../"
  name              = "pritunl"
  environment       = local.environment
  vpc_id            = module.vpc.vpc_id
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
  ami            = "ami-020cba7c55df1f615"
  instance_type  = "t2.micro"

  #Keypair
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB suresh@suresh"

  #Networking
  subnet_ids = tolist(module.public_subnets.public_subnet_id)

  #IAM
  iam_instance_profile = module.iam-role.name

  #Root Volume
  root_block_device = [
    {
      volume_type           = "gp3"
      volume_size           = 16
      delete_on_termination = true
    }
  ]

  #EBS Volume
  ebs_volume_enabled = true
  ebs_volume_type    = "gp3"
  ebs_volume_size    = 32

  #Tags
  instance_tags = { "snapshot" = true }
  #user data
  user_data = file("${path.module}/pritunl.sh")
}
