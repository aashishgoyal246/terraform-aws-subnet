#Module      : SUBNET
#Description : Terraform module to create public and public-private subnet with
#              network acl, route table, Elastic IP, NAT gateway, flow log.
output "public_subnet_cidrs" {
  value       = module.subnet.public_subnet_cidrs
  description = "The CIDR of the subnet."
}

output "public_tags" {
  value       = module.subnet.public_tags
  description = "A mapping of tags to assign to the resource."
}