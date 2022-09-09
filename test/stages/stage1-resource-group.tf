resource "random_string" "cluster_id" {
    length = 5
    special = false
    upper = false
}

locals {
  name_prefix = var.name_prefix == "" ? "${var.resource_group_name}-${random_string.cluster_id.result}" : "${var.name_prefix}-${random_string.cluster_id.result}"
}

module "resource_group" {
  source = "github.com/cloud-native-toolkit/terraform-azure-resource-group"

  resource_group_name = "${local.name_prefix}-rg"
  region              = var.region
}
