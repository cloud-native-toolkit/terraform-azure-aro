module "vpc" {
  source = "github.com/cloud-native-toolkit/terraform-azure-vpc"

  resource_group_name = module.resource_group.name
  region              = var.region
  name_prefix         = var.name_prefix
  address_prefix_count = 1
  address_prefixes    = ["10.0.0.0/8"]
  enabled             = module.resource_group.enabled
}
