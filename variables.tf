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

variable "master_subnet_id" {
  type        = string
  description = "The id of the subnet where the master nodes will be placed"
}

variable "worker_subnet_id" {
  type        = string
  description = "The id of the subnet where the worker nodes will be placed"
}

variable "openshift_version" {
  type        = string
  description = "The version of the openshift cluster"
  default     = "4.8.11"
}

variable "vpc_name" {
  type        = string
  description = "The name of the vpc"
}

variable "master_flavor" {
  type        = string
  description = "The size of the VMs for the master nodes"
  default     = "Standard_D8s_v3"
}

variable "flavor" {
  type        = string
  description = "The size of the VMs for the worker nodes"
  default     = "Standard_D8s_v3"
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

variable "disable_public_endpoint" {
  type        = bool
  description = "Flag to make the cluster private only"
  default     = false
}

variable "disk_size" {
  type        = number
  description = "The size in GB of the disk for each worker node"
  default     = 128
}

variable "pull_secret" {
  type        = string
  description = "The contents of the pull secret needed to access Red Hat content. The contents can either be provided directly or passed through the `pull_secret_file` variable"
  default     = ""
}

variable "pull_secret_file" {
  type        = string
  description = "Name of the file containing the pull secret needed to access Red Hat content. The contents can either be provided in this file or directly via the `pull_secret` variable"
  default     = ""
}

variable "label" {
  type        = string
  description = "The label used to generate the cluster name"
  default     = "cluster"
}
