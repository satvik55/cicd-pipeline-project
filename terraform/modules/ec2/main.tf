resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name    = "${var.project_name}-ec2-role"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.jenkins_instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.jenkins_subnet_id
  vpc_security_group_ids = [var.jenkins_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "${var.project_name}-jenkins-server"
    Role    = "jenkins"
    Project = var.project_name
  }
}

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.app_instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.app_subnet_id
  vpc_security_group_ids = [var.app_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "${var.project_name}-app-server"
    Role    = "app"
    Project = var.project_name
  }
}

# ============================================
# Elastic IPs — static public IPs
# ============================================
resource "aws_eip" "jenkins" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = {
    Name    = "${var.project_name}-jenkins-eip"
    Project = var.project_name
  }
}

resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name    = "${var.project_name}-app-eip"
    Project = var.project_name
  }
}
