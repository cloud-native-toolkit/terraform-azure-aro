module "vnet" {
  source = "github.com/cloud-native-toolkit/terraform-azure-vnet"

  resource_group_name = module.resource_group.name
  region              = module.resource_group.region
  name_prefix         = local.name_prefix
  address_prefixes    = ["${var.vnet_cidr}"]
}
