locals {
  public_count        = var.enabled && var.type == "public" || var.type == "public-private" ? 1 : 0
  private_count       = var.enabled && var.type == "public-private" ? length(var.availability_zones) : 0
  public_acl_enabled  = var.enabled && var.public_acl_enabled && var.type == "public" || var.type == "public-private" ? 1 : 0
  private_acl_enabled = var.enabled && var.private_acl_enabled && var.type == "public-private" ? 1 : 0
}

#Module      : LABELS
#Description : This terraform module is designed to generate consistent label names and
#              tags for resources. You can use terraform-labels to implement a strict
#              naming convention.
module "public_labels" {
  source = "git::https://github.com/aashishgoyal246/terraform-labels.git?ref=tags/0.12.0"

  name        = var.name
  application = var.application
  environment = var.environment
  enabled     = var.enabled
  label_order = var.label_order
  attributes  = compact(concat(var.attributes, list("public")))
  tags        = var.tags
}

module "private_labels" {
  source = "git::https://github.com/aashishgoyal246/terraform-labels.git?ref=tags/0.12.0"

  name        = var.name
  application = var.application
  environment = var.environment
  enabled     = var.enabled
  label_order = var.label_order
  attributes  = compact(concat(var.attributes, list("private")))
  tags        = var.tags
}

#Module      : PUBLIC SUBNET
#Description : Terraform module to create public, private and public-private subnet with
#              network acl, route table, Elastic IP, NAT gateway, flow log.
resource "aws_subnet" "public" {
  count = local.public_count

  vpc_id                          = var.vpc_id
  availability_zone               = element(var.availability_zones, count.index)
  cidr_block                      = cidrsubnet(var.cidr_block, 8, count.index)
  ipv6_cidr_block                 = var.ipv6_enabled ? cidrsubnet(var.ipv6_cidr_block, 8, count.index) : ""
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation

  tags = merge(
    module.public_labels.tags,
    {
      "Name" = format("%s%s%s", module.public_labels.id, var.delimiter, count.index + 1)
      "AZ"   = element(var.availability_zones, count.index)
    },
    var.tags
  )
}

#Module      : NETWORK ACL PUBLIC
#Description : Provides an network ACL resource. You might set up network ACLs with rules
#              similar to your security groups in order to add an additional layer of
#              security to your VPC.
resource "aws_network_acl" "public" {
  count = local.public_acl_enabled

  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.public.*.id

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  dynamic "ingress" {
    for_each = var.ipv6_enabled ? [1] : []
    
    content {
      rule_no         = 101
      action          = "allow"
      ipv6_cidr_block = "::/0"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
    }
  }

  egress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  dynamic "egress" {
    for_each = var.ipv6_enabled ? [1] : []
    
    content {
      rule_no         = 101
      action          = "allow"
      ipv6_cidr_block = "::/0"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
    }
  }

  tags       = module.public_labels.tags
  depends_on = [aws_subnet.public]
}

#Module      : ROUTE TABLE PUBLIC
#Description : Provides a resource to create a VPC routing table.
resource "aws_route_table" "public" {
  count = local.public_count

  vpc_id = var.vpc_id

  tags = merge(
    module.public_labels.tags,
    {
      "Name" = format("%s%s%s-rt", module.public_labels.id, var.delimiter, count.index + 1)
      "AZ"   = element(var.availability_zones, count.index)
    }
  )
}

#Module      : ROUTE PUBLIC
#Description : Provides a resource to create a routing table entry (a route) in a VPC
#              routing table.
resource "aws_route" "public" {
  count = local.public_count

  route_table_id         = join("", aws_route_table.public.*.id)
  gateway_id             = var.igw_id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.public]
}

resource "aws_route" "public_ipv6" {
  count = var.enabled && var.ipv6_enabled ? 1 : 0

  route_table_id              = join("", aws_route_table.public.*.id)
  gateway_id                  = var.igw_id
  destination_ipv6_cidr_block = "::/0"
  depends_on                  = [aws_route_table.public]
}

#Module      : ROUTE TABLE ASSOCIATION PUBLIC
#Description : Provides a resource to create an association between a subnet and routing
#              table.
resource "aws_route_table_association" "public" {
  count = local.public_count

  subnet_id      = join("", aws_subnet.public.*.id)
  route_table_id = join("", aws_route_table.public.*.id)
  
  depends_on = [
    aws_subnet.public,
    aws_route_table.public,
  ]
}

#Module      : FLOW LOG PUBLIC
#Description : Provides a VPC/Subnet/ENI Flow Log to capture IP traffic for a specific
#              network interface, subnet, or VPC. Logs are sent to a CloudWatch Log Group
#              or a S3 Bucket.
resource "aws_flow_log" "public" {
  count = var.enabled && var.public_flow_log_enabled ? 1 : 0

  traffic_type             = var.traffic_type
  log_destination_type     = var.log_destination_type
  log_destination          = var.log_destination_arn
  subnet_id                = element(aws_subnet.public.*.id, count.index)
  log_format               = var.log_format
  max_aggregation_interval = var.max_aggregation_interval
  tags                     = module.public_labels.tags
}

#Module      : PRIVATE SUBNET
#Description : Terraform module to create public, private and public-private subnet with
#              network acl, route table, Elastic IP, nat gateway, flow log.
resource "aws_subnet" "private" {
  count = local.private_count

  vpc_id                          = var.vpc_id
  availability_zone               = element(var.availability_zones, count.index)
  cidr_block                      = cidrsubnet(var.cidr_block, 8, local.private_count + count.index)
  ipv6_cidr_block                 = var.ipv6_enabled ? cidrsubnet(var.ipv6_cidr_block, 8, local.private_count + count.index) : ""
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation
  
  tags = merge(
    module.private_labels.tags,
    {
      "Name" = format("%s%s%s", module.private_labels.id, var.delimiter, count.index + 1)
      "AZ"   = element(var.availability_zones, count.index)
    },
    var.tags
  )
}

#Module      : NETWORK ACL PRIVATE
#Description : Provides an network ACL resource. You might set up network ACLs with rules
#              similar to your security groups in order to add an additional layer of
#              security to your VPC.
resource "aws_network_acl" "private" {
  count = local.private_acl_enabled

  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.private.*.id

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  dynamic "ingress" {
    for_each = var.ipv6_enabled ? [1] : []
    
    content {
      rule_no         = 101
      action          = "allow"
      ipv6_cidr_block = "::/0"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
    }
  }

  egress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  dynamic "egress" {
    for_each = var.ipv6_enabled ? [1] : []
    
    content {
      rule_no         = 101
      action          = "allow"
      ipv6_cidr_block = "::/0"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
    }
  }

  tags       = module.private_labels.tags
  depends_on = [aws_subnet.private]
}

#Module      : ROUTE TABLE PRIVATE
#Description : Provides a resource to create a VPC routing table.
resource "aws_route_table" "private" {
  count = var.enabled && var.type == "public-private" ? 1 : 0

  vpc_id = var.vpc_id
  
  tags = merge(
    module.private_labels.tags,
    {
      "Name" = format("%s%s%s-rt", module.private_labels.id, var.delimiter, count.index + 1)
      "AZ"   = element(var.availability_zones, count.index)
    }
  )
}

#Module      : ROUTE PRIVATE
#Description : Provides a resource to create a routing table entry (a route) in a VPC
#              routing table.
resource "aws_route" "private" {
  count = var.enabled && var.type == "public-private" ? 1 : 0

  route_table_id         = join("", aws_route_table.private.*.id)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = join("", aws_nat_gateway.private.*.id)
  depends_on             = [aws_route_table.private]
}

#Module      : ROUTE EGRESS ONLY INTERNET GATEWAY
#Description : Provides a resource to create a routing table entry (a route) in a VPC
#              routing table.
resource "aws_route" "egress" {
  count = var.enabled && var.ipv6_enabled ? 1 : 0

  route_table_id              = join("", aws_route_table.private.*.id)
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = join("", aws_egress_only_internet_gateway.ipv6.*.id)
  depends_on                  = [aws_route_table.private]
}

#Module      : ROUTE TABLE ASSOCIATION PRIVATE
#Description : Provides a resource to create an association between a subnet and routing
#              table.
resource "aws_route_table_association" "private" {
  count = local.private_count

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)

  depends_on = [
    aws_subnet.private,
    aws_route_table.private,
  ]
}

#Module      : EIP
#Description : Provides an Elastic IP resource..
resource "aws_eip" "private" {
  count = var.enabled && var.type == "public-private" && var.nat_gateway_enabled ? 1 : 0

  vpc = true
  
  tags = merge(
    module.private_labels.tags,
    {
      "Name" = format("%s%s%s-eip", module.private_labels.id, var.delimiter, count.index + 1)
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}

#Module      : NAT GATEWAY
#Description : Provides a resource to create a VPC NAT Gateway.
resource "aws_nat_gateway" "private" {
  count = var.enabled && var.type == "public-private" && var.nat_gateway_enabled ? 1 : 0

  allocation_id = join("", aws_eip.private.*.id)
  subnet_id     = join("", aws_subnet.public.*.id)
  
  tags = merge(
    module.private_labels.tags,
    {
      "Name" = format("%s%s%s-ng", module.private_labels.id, var.delimiter, count.index + 1)
    }
  )
}

#Module      : EGRESS ONLY INTERNET GATEWAY
#Description : Provides a resource to create a VPC Egress only Internet Gateway for IPV6.
resource "aws_egress_only_internet_gateway" "ipv6" {
  count  = var.enabled && var.ipv6_enabled ? 1 : 0
  vpc_id = var.vpc_id
  
  tags = merge(
    module.private_labels.tags,
    {
      "Name" = format("%s%s%s-egress-ig", module.private_labels.id, var.delimiter, count.index + 1)
    }
  )
}

#Module      : Flow Log
#Description : Provides a VPC/Subnet/ENI Flow Log to capture IP traffic for a specific
#              network interface, subnet, or VPC. Logs are sent to a CloudWatch Log Group
#              or a S3 Bucket.
resource "aws_flow_log" "private_subnet_flow_log" {
  count = var.enabled && var.private_flow_log_enabled ? length(var.availability_zones) : 0

  traffic_type             = var.traffic_type
  log_destination_type     = var.log_destination_type
  log_destination          = var.log_destination_arn
  subnet_id                = element(aws_subnet.private.*.id, count.index)
  log_format               = var.log_format
  max_aggregation_interval = var.max_aggregation_interval
  tags                     = module.public_labels.tags
}