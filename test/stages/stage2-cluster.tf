module "cluster" {
  source = "./module"

  name_prefix           = var.name_prefix
  
  subscription_id       = var.azure_subscription_id
  tenant_id             = var.azure_tenant_id
  client_id             = var.service_principal_id
  client_secret         = var.service_principal_secret

  resource_group_name   = module.resource_group.name
  region                = module.resource_group.region
  vnet_name             = module.vnet.name
  master_subnet_id      = module.master-subnet.id
  worker_subent_id      = module.worker-subnet.id
}

