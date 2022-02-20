variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the cluster will be provisioned"
}

variable "subscription_id" {
  type        = string
  description = "The id of the subscription where the cluster will be provisioned"
}

variable "tenant_id" {
  type        = string
  description = "The id of the tenant within the subscription to provision the cluster"
}

variable "client_id" {
  type        = string
  description = "The client_id or username to access the tenant"
}

variable "client_secret" {
  type        = string
  description = "The secret used to access the tenant"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "The location where the cluster should be provisioned"
}

variable "master_cidr" {
  type        = string
  description = "The CIDR block for the master network"
}

variable "worker_cidr" {
  type        = string
  description = "The CIDR block for the worker network"
}

variable "openshift_version" {
  type        = string
  description = "The version of the openshift cluster"
  default     = "4.8"
}

variable "vpc_name" {
  type        = string
  description = "The name of the vpc"
}

variable "master_flavor" {
  type        = string
  description = "The size of the VMs for the master nodes"
  default     = "Standard_D4s_v3"
}

variable "flavor" {
  type        = string
  description = "The size of the VMs for the worker nodes"
  default     = "Standard_D4s_v3"
}

variable "master_count" {
  type        = number
  description = "The number of master nodes"
  default     = 3
}

variable "infra_count" {
  type        = number
  description = "The number of infrastructure worker nodes"
  default     = 2
}

variable "_count" {
  type        = number
  description = "The number of compute worker nodes"
  default     = 3
}

variable "os_type" {
  type        = string
  description = "The type of os for the master and worker nodes"
  default     = "Linux"
}

variable "provision" {
  type        = bool
  description = "Flag indicating the cluster should be provisioned. If the value is false then an existing cluster will be looked up"
  default     = true
}

variable "enabled" {
  type        = bool
  description = "Flag indicating the module should be enabled"
  default     = true
}

variable "name" {
  type        = string
  description = "The name of the ARO cluster. If empty the name will be derived from the name prefix"
  default     = ""
}

variable "name_prefix" {
  type        = string
  description = "The prefix name for the service. If not provided it will default to the resource group name"
  default     = ""
}

variable "auth_group_id" {
  type        = string
  description = "The id of the auth group for cluster admins"
  default     = ""
}
