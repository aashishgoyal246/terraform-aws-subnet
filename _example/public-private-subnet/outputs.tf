#Module      : SUBNET
#Description : Terraform module to create publicand public-private subnet with
#              network acl, route table, Elastic IP, NAT gateway, flow log.
output "public_subnet_cidrs" {
  value       = module.subnet.public_subnet_cidrs
  description = "The CIDR of the subnet."
}

output "private_subnet_cidrs" {
  value       = module.subnet.private_subnet_cidrs
  description = "The CIDR of the subnet."
}

output "private_tags" {
  value       = module.subnet.private_tags
  description = "A mapping of tags to assign to the resource."
}

output "public_tags" {
  value       = module.subnet.public_tags
  description = "A mapping of tags to assign to the resource."
}