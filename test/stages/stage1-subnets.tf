locals {
  subnet_cidrs       = cidrsubnets(var.vnet_cidr, 2, 2)
}

module "master_subnets" {
  source = "github.com/cloud-native-toolkit/terraform-azure-subnets"

  region              = module.resource_group.region
  resource_group_name = module.resource_group.name
  vnet_name            = module.vnet.name
  ipv4_cidr_blocks    = ["${local.subnet_cidrs[0]}"]
  label               = "master"
  acl_rules           = []
  service_endpoints   = ["Microsoft.ContainerRegistry","Microsoft.Storage"]
}

module "worker_subnets" {
  source = "github.com/cloud-native-toolkit/terraform-azure-subnets"

  region              = module.resource_group.region
  resource_group_name = module.resource_group.name
  vnet_name            = module.vnet.name
  ipv4_cidr_blocks    = ["${local.subnet_cidrs[1]}"]
  label               = "worker"
  acl_rules           = []
  service_endpoints   = ["Microsoft.ContainerRegistry","Microsoft.Storage"]
}
