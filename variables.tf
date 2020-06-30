#Module      : LABELS
#Description : Terraform label module variables.
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "application" {
  type        = string
  default     = ""
  description = "Application (e.g. `aashish`)."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "enabled" {
  type        = bool
  default     = false
  description = "Flag to control the vpc creation."
}

variable "label_order" {
  type        = list
  default     = []
  description = "Label order, e.g. `name`,`application`."
}

variable "tags" {
  type        = map
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}

variable "attributes" {
  type        = list
  default     = []
  description = "Additional attributes (e.g. `1`)."
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `organization`, `environment`, `name` and `attributes`."
}

#Module      : SUBNET
#Description : Terraform SUBNET module variables.
variable "vpc_id" {
  type        = string
  default     = ""
  description = "VPC ID."
}

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)."
}

variable "cidr_block" {
  type        = string
  default     = ""
  description = "Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)."
}

variable "ipv6_enabled" {
  type        = bool
  default     = false
  description = "Whether IPV6 is enabled or not."
}

variable "ipv6_cidr_block" {
  type        = string
  default     = ""
  description = "Base CIDR block for the IPV6."
}

variable "assign_ipv6_address_on_creation" {
  type        = bool
  default     = false
  description = "Whether assign IPV6 address to network interface or not."
}

variable "type" {
  type        = string
  default     = ""
  description = "Type of subnets to create (`private` or `public`)."
}

variable "public_acl_enabled" {
  type        = bool
  default     = true
  description = "Whether public ACL is enabled or not."
}

variable "igw_id" {
  type        = string
  default     = ""
  description = "Internet Gateway ID that is used as a default route when creating public subnets (e.g. `igw-9c26a123`)."
}

variable "public_flow_log_enabled" {
  type        = bool
  default     = false
  description = "Whether public flow log is enabled or not."
}

variable "traffic_type" {
  type        = string
  default     = ""
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL."
}

variable "log_destination_type" {
  type        = string
  default     = ""
  description = "The type of the logging destination. Valid values: cloud-watch-logs, s3. Default: cloud-watch-logs."
}

variable "log_destination_arn" {
  type        = string
  default     = ""
  description = "The ARN of the logging destination."
}

variable "log_format" {
  type        = string
  default     = ""
  description = "The fields to include in the flow log record, in the order in which they should appear."
}

variable "max_aggregation_interval" {
  type        = number
  default     = 600
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record."
}

variable "private_acl_enabled" {
  type        = bool
  default     = true
  description = "Whether private ACL is enabled or not."
}

variable "az_ngw_ids" {
  type        = map(string)
  default     = {}
  description = "Only for private subnets. Map of AZ names to NAT Gateway IDs that are used as default routes when creating private subnets."
}

variable "nat_gateway_enabled" {
  type        = bool
  default     = false
  description = "Flag to enable/disable NAT Gateways creation in public subnets."
}

variable "private_flow_log_enabled" {
  type        = bool
  default     = false
  description = "Whether private flow log is enabled or not."
}