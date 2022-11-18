module "cluster" {
  source = "./module"

  name_prefix           = local.name_prefix
  
  subscription_id       = var.subscription_id
  tenant_id             = var.tenant_id
  client_id             = var.client_id
  client_secret         = var.client_secret

  resource_group_name   = module.resource_group.name
  region                = module.resource_group.region
  vnet_name             = module.vnet.name
  master_subnet_id      = module.master-subnet.id
  worker_subnet_id      = module.worker-subnet.id

  encrypt               = true
  #enable_purge          = true
}

# output "config_file_path" {
#   value = module.cluster.config_file_path
# }

