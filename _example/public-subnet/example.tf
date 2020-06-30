provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source = "git::https://github.com/aashishgoyal246/terraform-aws-vpc.git?ref=tags/0.12.1"

  name        = "vpc"
  application = "aashish"
  environment = "test"
  label_order = ["environment", "application", "name"]

  enabled                          = true
  cidr_block                       = "10.10.0.0/16"
  assign_generated_ipv6_cidr_block = true
}

module "subnet" {
  source = "../../"

  name        = "subnet"
  application = "aashish"
  environment = "test"
  label_order = ["environment", "application", "name"]

  enabled            = true
  availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  vpc_id             = module.vpc.vpc_id
  type               = "public"
  igw_id             = module.vpc.ig_id
  cidr_block         = module.vpc.vpc_cidr_block
  ipv6_enabled       = true
  ipv6_cidr_block    = module.vpc.vpc_ipv6_cidr_block
}