resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr


  tags =  {
    name = "${var.env}-${var.project_name}-vpc"
  }
}

resource "aws_subnet" "main" {
  count               = length(var.subnets_cidr)
  vpc_id              = aws_vpc.main.id
  cidr_block          = element(var.subnets_cidr,count.index)
  availability_zone   = element(var.az, count.index)

  tags = {
    Name = "subnet-${count.index}"
  }
}


resource "aws_vpc_peering_connection" "main" {
  peer_vpc_id   = data.aws_vpc.default.id
  vpc_id        = aws_vpc.main.id
  auto_accept   = true

  tags = {
    name = "${var.env}-vpc-with-default-vpc"
  }
}