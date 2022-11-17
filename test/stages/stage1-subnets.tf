locals {
  subnet_cidrs       = cidrsubnets(var.vnet_cidr, 2, 2)
}

module "master-subnet" {
  source = "github.com/cloud-native-toolkit/terraform-azure-subnets"

  region              = module.resource_group.region
  resource_group_name = module.resource_group.name
  vnet_name            = module.vnet.name
  ipv4_cidr_blocks    = ["${local.subnet_cidrs[0]}"]
  disable_private_link_endpoint_network_policies = true
  disable_private_link_service_network_policies = true
  label               = "master"
  acl_rules           = []
  service_endpoints   = ["Microsoft.ContainerRegistry","Microsoft.Storage"]
}

module "worker-subnet" {
  source = "github.com/cloud-native-toolkit/terraform-azure-subnets"

  region              = module.resource_group.region
  resource_group_name = module.resource_group.name
  vnet_name            = module.vnet.name
  ipv4_cidr_blocks    = ["${local.subnet_cidrs[1]}"]
  label               = "worker"
  acl_rules           = []
  service_endpoints   = ["Microsoft.ContainerRegistry","Microsoft.Storage"]
}
