module "cluster" {
  source = "./module"

  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  client_id = var.client_id
  client_secret = var.client_secret
  resource_group_name = var.resource_group_name
  region = var.region
  master_subnet_id = module.master_subnets.id
  worker_subnet_id = module.worker_subnets.id
  vpc_name = module.vpc.name
}
