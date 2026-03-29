module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  aws_region   = var.aws_region
}

module "security_groups" {
  source       = "./modules/security-groups"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  my_ip        = var.my_ip
}

module "ec2" {
  source                = "./modules/ec2"
  project_name          = var.project_name
  ami_id                = var.ami_id
  jenkins_instance_type = var.jenkins_instance_type
  app_instance_type     = var.app_instance_type
  key_pair_name         = var.key_pair_name
  jenkins_subnet_id     = module.vpc.public_subnet_1_id
  app_subnet_id         = module.vpc.public_subnet_2_id
  jenkins_sg_id         = module.security_groups.jenkins_sg_id
  app_sg_id             = module.security_groups.app_sg_id
}
