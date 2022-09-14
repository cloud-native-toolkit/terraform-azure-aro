
# Resource Group Variables
variable "resource_group_name" {
  type        = string
  description = "Name of the network resource group."
}

variable "region" {
  type        = string
  description = "Azure region/location to deploy resources."
}

variable "name_prefix" {
  type        = string
  description = "Prefix name that should be used for the cluster and services. If not provided then resource_group_name will be used"
  default     = ""
}

variable "vnet_cidr" {
  type = string
  description = "CIDR for VNet"
  default = "10.0.0.0/18"
}

variable "subscription_id" {}

variable "client_id" {}

variable "client_secret" {}

variable "tenant_id" {}

