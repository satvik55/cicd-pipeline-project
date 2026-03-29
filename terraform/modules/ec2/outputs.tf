output "jenkins_public_ip" { value = aws_eip.jenkins.public_ip }
output "jenkins_instance_id" { value = aws_instance.jenkins.id }
output "app_public_ip" { value = aws_eip.app.public_ip }
output "app_instance_id" { value = aws_instance.app.id }
output "jenkins_eip_id" { value = aws_eip.jenkins.id }
output "app_eip_id" { value = aws_eip.app.id }
output "app_private_ip" { value = aws_instance.app.private_ip }
