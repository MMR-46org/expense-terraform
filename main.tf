module "vpc" {
  source               =   "./modules/vpc"
  for_each             =   var.vpc

  vpc_cidr             =   lookup(each.value, "vpc_cidr", null)
  public_subnets_cidr  =  lookup(each.value, "public_subnets_cidr", null)
  web_subnets_cidr     =  lookup(each.value, "web_subnets_cidr", null)
  app_subnets_cidr     =  lookup(each.value, "app_subnets_cidr", null)
  db_subnets_cidr      =  lookup(each.value, "db_subnets_cidr", null)
  az                   =  lookup(each.value, "az", null)



  env                  =  var.env
  project_name         =  var.project_name
}


module "rds" {
  source         =   "./modules/rds"
  for_each       =   var.rds


  env              = var.env
  project_name     = var.project_name
  kms_key_id       = var.kms_key_id


  allocated_storage = lookup(each.value, "allocated_storage", null)
  db_name          =  lookup(each.value, "db_name", null)
  engine           = lookup(each.value, "engine", null)
  engine_version   = lookup(each.value, "engine_version", null)
  instance_class   = lookup(each.value, "instance_class", null)
  family           =  lookup(each.value, "family", null)


  subnet_ids       = lookup(lookup(module.vpc, "main", null), "db_subnet_id", null)
  vpc_id           = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  sg_cidr_blocks   = lookup(lookup(var.vpc, "main", null), "app_subnets_cidr", null)

}


module "backend" {
  depends_on           = [module.rds]
  source               = "./modules/app"
  for_each             = var.app

  bastion_cidrs        = var.bastion_cidrs
  prometheus_cidrs     = var.prometheus_cidrs
  component            = "backend"
  env                  = var.env
  kms_key_id           = var.kms_key_id
  project_name         = var.project_name


  app_port             = lookup(each.value, "backend_app_port", null)
  instance_capacity    = lookup(each.value, "backend_instance_capacity", null)
  instance_type        = lookup(each.value, "backend_instance_type", null)
  parameters           = ["arn:aws:ssm:us-east-1:512646826903:parameter/${var.env}.${var.project_name}.rds.*", "arn:aws:ssm:us-east-1:512646826903:parameter/newrelic.*","arn:aws:ssm:us-east-1:512646826903:parameter/artifactory.*"]


  sg_cidr_block        = lookup(lookup(var.vpc, "main", null), "app_subnets_cidr" , null)
  vpc_id               = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  vpc_zone_identifier  = lookup(lookup(module.vpc, "main", null), "app_subnet_id", null)
}


module "frontend" {
  source               = "./modules/app"
  for_each             = var.app

  bastion_cidrs        = var.bastion_cidrs
  prometheus_cidrs     = var.prometheus_cidrs
  component            = "frontend"
  env                  = var.env
  kms_key_id           = var.kms_key_id
  project_name         = var.project_name



  app_port             = lookup(each.value, "frontend_app_port", null)
  instance_capacity    = lookup(each.value, "frontend_instance_capacity", null)
  instance_type        = lookup(each.value, "frontend_instance_type", null)
  parameters           = ["arn:aws:ssm:us-east-1:512646826903:parameter/newrelic.*","arn:aws:ssm:us-east-1:512646826903:parameter/artifactory.*"]


  sg_cidr_block        = lookup(lookup(var.vpc, "main", null), "public_subnets_cidr" , null)
  vpc_id               = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  vpc_zone_identifier  = lookup(lookup(module.vpc, "main", null), "web_subnet_id", null)
}


module  "public_alb" {
  source            = "./modules/alb"
  for_each          = var.alb

  env            = var.env
  project_name   = var.project_name
  acm_arn        = var.acm_arn
  dns_name       =  "frontend"
  zone_id        = var.zone_id


  alb_name       = lookup(each.value, "alb_name" ,null)
  internal       = lookup(each.value, "internal", null)
  sg_cidr_blocks = lookup(each.value, "sg_cidr_blocks", null)

  subnets          = lookup(lookup(module.vpc, "main", null), "public_subnet_id", null)
  vpc_id           = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  target_group_arn = lookup(lookup(module.frontend, "main", null), "target_group_arn", null)
}


module  "private_alb" {
  source              =   "./modules/alb"
  for_each            =   var.alb

  env                 =  var.env
  project_name        =  var.project_name
  acm_arn             =  var.acm_arn
  dns_name            =  "backend"
  zone_id             = var.zone_id

  alb_name    = lookup(each.value, "private_alb_name", null)
  internal    = lookup(each.value, "private_internal", null)

  sg_cidr_blocks = lookup(lookup(var.vpc, "main", null), "web_subnets_cidr", null)
  subnets        = lookup(lookup(module.vpc, "main", null), "app_subnet_id", null)
  vpc_id         = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  target_group_arn = lookup(lookup(module.backend, "main", null), "target_group_arn", null)

}