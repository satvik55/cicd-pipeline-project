output "jenkins_public_ip" { value = module.ec2.jenkins_public_ip }
output "app_public_ip" { value = module.ec2.app_public_ip }
output "jenkins_instance_id" { value = module.ec2.jenkins_instance_id }
output "app_instance_id" { value = module.ec2.app_instance_id }
output "vpc_id" { value = module.vpc.vpc_id }
output "app_private_ip" { value = module.ec2.app_private_ip }
