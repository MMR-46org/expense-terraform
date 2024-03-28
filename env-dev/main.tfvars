env                         = "dev"
project_name                = "expense"
kms_key_id                  = "arn:aws:kms:us-east-1:512646826903:key/91ae5e2e-d734-4d42-b51d-1acf22378265"
bastion_cidrs               = ["172.31.15.146/32"]
prometheus_cidrs            = ["172.31.42.220/32"]
acm_arn                     = "arn:aws:acm:us-east-1:512646826903:certificate/dc09d2e1-e117-481f-ade8-aad6b14f165d"
zone_id                     = "Z0189341LG4L24HIU4QF"



vpc  = {
  main = {
    vpc_cidr                =  "10.10.0.0/21"
    public_subnets_cidr     =  ["10.10.0.0/25", "10.10.0.128/25"]
    web_subnets_cidr        =  ["10.10.1.0/25", "10.10.1.128/25"]
    app_subnets_cidr        =  ["10.10.2.0/25", "10.10.2.128/25"]
    db_subnets_cidr         =  ["10.10.3.0/25", "10.10.3.128/25"]
    az                      =   ["us-east-1a", "us-east-1b"]

  }
}



rds = {
  main = {
    allocated_storage    = 10
    db_name              = "expense"
    engine               = "mysql"
    engine_version       = "5.7"
    instance_class       = "db.t3.micro"
    family               = "mysql5.7"
    }

}


app = {
  main  = {
    backend_app_port          = 8080
    backend_instance_capacity = 1
    backend_instance_type     = "t3.small"


    frontend_app_port       = 80
    frontend_instance_capacity = 1
    frontend_instance_type    = "t3.small"


  }
}

alb = {
  main = {
    alb_name               =  "public"
    internal               =  false
    sg_cidr_blocks         = ["0.0.0.0/0"]


    private_alb_name       =  "private"
    private_internal       =  true

  }
}