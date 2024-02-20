resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.alb_name}"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    =  [aws_security_group.main.id]
  subnets            = var.subnets


  tags = {
    Environment = "${local.name}-alb"
  }
}








resource "aws_security_group" "main" {
  name        = "${local.name}-alb-security-group"
  description = "${local.name}-alb-security-group"
  vpc_id      =  var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.sg_cidr_blocks
    description      = "HTTP"
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.sg_cidr_blocks
    description      = "HTTPS"
  }

  tags = {
    Name = "${local.name}-alb-sg"
  }
}

