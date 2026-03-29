variable "project_name" {
  type = string
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

variable "jenkins_subnet_id" {
  type = string
}

variable "app_subnet_id" {
  type = string
}

variable "jenkins_sg_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}
