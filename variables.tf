variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the cluster will be provisioned"
}

variable "client_secret" {
  type        = string
  description = "The secret used to access the subscription"
  sensitive   = true
  default     = ""
}

variable "master_subnet_id" {
  type        = string
  description = "The id of the subnet where the master nodes will be placed"
}

variable "worker_subnet_id" {
  type        = string
  description = "The id of the subnet where the worker nodes will be placed"
}

variable "vnet_name" {
  type        = string
  description = "The name of the VNet"
}

variable "master_flavor" {
  type        = string
  description = "The size of the VMs for the master nodes"
  default     = "Standard_D8s_v3"
}

variable "worker_flavor" {
  type        = string
  description = "The size of the VMs for the worker nodes"
  default     = "Standard_D4s_v3"
}

variable "worker_count" {
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

variable "disable_public_endpoint" {
  type        = bool
  description = "Flag to make the cluster private only"
  default     = false
}

variable "worker_disk_size" {
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

variable "encrypt" {
  type        = bool
  description = "Flag to encrypt the VM disks (default = false)"
  default     = false
}

variable "pod_cidr" {
  type        = string
  description = "CIDR for the POD subnet (default = \"10.128.0.0/14\")"
  default     = "10.128.0.0/14"
}

variable "service_cidr" {
  type        = string
  description = "CIDR for the services subnet (default = \"172.30.0.0/16\")"
  default     = "172.30.0.0/16"
}
variable "fips" {
  type        = bool
  description = "Flag to determine if FIPS validated modules should be utilized (default = false)"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "List of tags to be included as \"name\":\"value\" pairs (default = {})"
  default     = {}
}

