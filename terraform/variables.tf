variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "cicd-pipeline"
}

variable "ami_id" {
  type = string
}

variable "jenkins_instance_type" {
  type    = string
  default = "t3.small"
}

variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_pair_name" {
  type = string
}

variable "my_ip" {
  type = string
}
