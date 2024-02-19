resource "aws_launch_template" "main" {
  name_prefix   = "${local.name}-lanuch-templeate"
  image_id      = data.aws_ami.centos8.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
}

resource "aws_autoscaling_group" "main" {
  desired_capacity   = var.instance_capacity
  max_size           = var.instance_capacity
  min_size           = var.instance_capacity
  vpc_zone_identifier = var.vpc_zone_identifier

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tags = {
    key                 = "name"
    value               = local.name
    propagate_at_launch = true
  }
}



resource "aws_security_group" "main" {
  name        = "${local.name}-security-group"
  description = "${local.name}-security-group"
  vpc_id      =  var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidrs
    description      = "SSH"
  }

  ingress {
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = var.sg_cidr_block
    description      = "APPPORT"
  }

  tags = {
    Name = "${local.name}-sg"
  }
}





