provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source = "git::https://github.com/aashishgoyal246/terraform-aws-vpc.git?ref=tags/0.12.0"

  name        = "vpc"
  application = "aashish"
  environment = "test"
  label_order = ["environment", "application", "name"]

  enabled    = true
  cidr_block = "10.10.0.0/16"
}

module "subnet" {
  source = "../../"

  name        = "subnet"
  application = "aashish"
  environment = "test"
  label_order = ["environment", "application", "name"]

  enabled             = true
  availability_zones  = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  vpc_id              = module.vpc.vpc_id
  type                = "public-private"
  igw_id              = module.vpc.ig_id
  cidr_block          = module.vpc.vpc_cidr_block

  public_flow_log_enabled = true
  traffic_type            = "ALL"
  log_destination_type    = "s3"
  log_destination         = 

  private_flow_log_enabled = true
  traffic_type             = "ALL"
  log_destination_type     = "s3"
  log_destination          = 
}