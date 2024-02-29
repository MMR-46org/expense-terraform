resource "aws_launch_template" "main" {
  name_prefix   = "${local.name}-lanuch-template"
  image_id      = data.aws_ami.centos8.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]

  user_data        = base64encode(templatefile("${path.module}/userdata.sh",{
    service_name   = var.component
    env            = var.env
  } ))

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 10
      encrypted   = true
      kms_key_id  = var.kms_key_id
      delete_on_termination = true
    }
  }

}


resource "aws_autoscaling_group" "main" {
  desired_capacity   = var.instance_capacity
  max_size           = var.instance_capacity
  min_size           = var.instance_capacity
  vpc_zone_identifier = var.vpc_zone_identifier
  target_group_arns    = [aws_lb_target_group.main.arn]


  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag  {
    key                 = "Name"
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


resource "aws_lb_target_group" "main" {
  name     = "${local.name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                  = "/health"
    healthy_threshold     = 2
    unhealthy_threshold   = 2
    interval              = 5
    timeout               = 2

  }
}


resource "aws_iam_role" "main" {
  name               = "${local.name}-role"

  assume_role_policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Action    = "sts:AssumeRole"
          Effect    = "Allow"
          Sid       = ""
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
    })


  inline_policy {
    name  = "kms-key-policy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "kmskeyPermission",
          "Effect": "Allow",

            "AWS": [
              "arn:aws:iam::512646826903:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
            ],
          "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource": "*"
        },
        {
          "Sid": "kmsGrant",
          "Effect": "Allow",

            "AWS": [
              "arn:aws:iam::512646826903:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
            ],
          "Action": [
            "kms:CreateGrant"
          ],
          "Resource": "*",
          "Condition": {
            "Bool": {
              "kms:GrantIsForAWSResource": true
            }
          }
        }

      ]
    })
  }

  inline_policy {
    name = "parameter-store"

    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "GetParameter",
          "Effect": "Allow",
          "Action": [
            "kms:Decrypt",
            "ssm:GetParameterHistory",
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter"
          ],
          "Resource": concat ([
            "arn:aws:ssm:us-east-1:512646826903:parameter/${var.env}.${var.project_name}.${var.component}.*",
            "arn:aws:kms:us-east-1:512646826903:key/91ae5e2e-d734-4d42-b51d-1acf22378265",
          ],var.parameters)
        },
        {
          "Sid" : "DescribeAllParameters",
          "Effect" : "Allow",
          "Action" : "ssm:DescribeParameters",
          "Resource" : "*"
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "main" {
  name = "${local.name}-role"
  role = aws_iam_role.main.name
}


