data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}

module "main_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs = ["us-west-2a","us-west-2b","us-west-2c"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}

module "main_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  #version = "4.13.0"

  name                = "main-security-group"
  description         = "Security Group for Main service"
  vpc_id              = module.main_vpc.vpc_id
  ingress_rules       = ["https-443-tcp","http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]

}

module "main_alb" {
  source  = "terraform-aws-modules/alb/aws"
  #version = "~> 6.0"

  name               = "main-alb"
  load_balancer_type = "application"

  vpc_id          = module.main_vpc.vpc_id
  subnets         = module.main_vpc.public_subnets
  security_groups = [module.main_sg.security_group_id]

  target_groups = [
    {
      name_prefix = "main-"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
    }
  ]

  listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      #target_group_index = 0
    }
  ]

  tags = var.environment.tags
}

module "main_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  #version = "6.5.2"
  
  name = "main-asg"
  min_size                  = var.environment.asg_min
  max_size                  = var.environment.asg_max
  vpc_zone_identifier       = var.module.main_vpc.public_subnets
  target_group_arns         = module.main_alb.target_group_arns
  security_groups           = [module.main_sg.security_group_id]
  instance_type             = var.instance_type
  image_id                  = data.aws_ami.id
}