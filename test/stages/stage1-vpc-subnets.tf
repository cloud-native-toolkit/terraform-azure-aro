module "master_subnets" {
  source = "github.com/cloud-native-toolkit/terraform-azure-vpc-subnets"

  region = var.region
  resource_group_name = module.resource_group.name
  vpc_name = module.vpc.name
  _count = 1
  ipv4_cidr_blocks = ["10.1.1.0/24"]
  label = "master"
  disable_private_link_endpoint_network_policies = true
}

module "worker_subnets" {
  source = "github.com/cloud-native-toolkit/terraform-azure-vpc-subnets"

  region = var.region
  resource_group_name = module.resource_group.name
  vpc_name = module.vpc.name
  _count = 1
  ipv4_cidr_blocks = ["10.1.2.0/24"]
  label = "worker"
}
