module "vpc" {
  source               = "./modules/vpc"
  for_each             = var.vpc
  vpc_cidr             = lookup(each.value, "vpc_cidr", null)
  public_subnets_cidr  = lookup (each.value, "public_subnets_cidr", null)
  web_subnets_cidr     = lookup(each.value, "web_subnets_cidr", null)
  app_subnets_cidr     = lookup(each.value, "app_subnets_cidr", null)
  db_subnets_cidr      =  lookup(each.value, "db_subnets_cidr", null)
  az                   = lookup(each.value, "az", null)
  env                  = var.env
  project_name         = var.project_name

}


module "rds" {
  source            = "./modules/rds"
  for_each          = var.rds
  allocated_storage = lookup(each.value, "allocated_storage", null)
  engine            = lookup(each.value, "engine", null)
  engine_version    = lookup(each.value, "engine_version", null)
  instance_class    = lookup(each.value, "instance_class", null)
  db_name           = lookup(each.value, "db_name", null)
  family            = lookup(each.value, "family", null)


  env               = var.env
  project_name      = var.project_name
  kms_key_id        = var.kms_key_id

  subnet_ids        = lookup(lookup(module.vpc, "main", null), "db_subnets_ids" , null)
  vpc_id            = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  sg_cidr_blocks    = lookup(lookup(var.vpc, "main", null),"app_subnets_cidr", null)


}



module "backend" {
  source      = "./modules/app"
  for_each    = var.app

  project_name     = var.project_name
  bastion_cidrs    =  var.bastion_cidr
  component        =  "backend"
  env              =  var.env


  app_port         =  lookup(each.value, "backend_app_port", null)
  instance_capacity=  lookup(each.value, "backend_instance_capacity", null)
  instance_type    = lookup(each.value, "backend_instance_type", null)


  sg_cidr_block              = lookup(lookup(var.vpc, "main", null), "app_subnets_cidr", null)
  vpc_id                     = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  vpc_zone_identifier        = lookup(lookup(module.vpc, "main", null), "app_subnets_ids",  null)
  parameters                 = ["arn:aws:ssm:us-east-1:512646826903:parameter/${var.env}.${var.project_name}.rds.*"]
}



module "frontend" {
  source       =  "./modules/app"
  for_each     = var.app

  env          = var.env
  project_name = var.project_name
  bastion_cidrs = var.bastion_cidr
  component    = "frontend"


  app_port     = lookup(each.value, "frontend_app_port", null)
  instance_capacity = lookup(each.value, "frontend_instance_capacity", null)
  instance_type  =  lookup(each.value, "frontend_instance_type", null)


  sg_cidr_block  = lookup(lookup(var.vpc, "main", null), "public_subnets_cidr", null)
  vpc_id         = lookup(lookup(module.vpc, "main", null),"vpc_id", null)
  vpc_zone_identifier    = lookup(lookup(module.vpc, "main", null), "web_subnets_ids", null)
  parameters             = []


}


module "public-alb" {
  source         = "./modules/alb"


  alb_name       = "public"
  env            = var.env
  internal       = false
  project_name   = var.project_name
  acm_arn        = var.acm_arn
  dns_name       = "frontend"
  zone_id        = var.zone_id


  sg_cidr_blocks = ["0.0.0.0/0"]
  subnets        = lookup(lookup(module.vpc, "main", null), "public_subnets_ids", null)
  vpc_id         = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  target_group_arn = lookup(lookup(module.frontend, "main", null), "target_group_arn", null)
}



module "private-lb" {
  source         = "./modules/alb"


  alb_name       = "private"
  env            = var.env
  internal       = true
  project_name   = var.project_name
  acm_arn        = var.acm_arn
  dns_name       = "backend"
  zone_id        =  var.zone_id

  sg_cidr_blocks = lookup(lookup(var.vpc, "main", null), "web_subnets_cidr", null)
  subnets        = lookup(lookup(module.vpc, "main", null), "app_subnets_ids", null)
  vpc_id         = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  target_group_arn = lookup(lookup(module.backend, "main", null), "target_group_arn", null)
}

