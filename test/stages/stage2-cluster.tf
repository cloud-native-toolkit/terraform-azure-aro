module "cluster" {
  source = "./module"

  name_prefix           = local.name_prefix
  
  client_secret         = var.client_secret

  resource_group_name   = module.resource_group.name
  vnet_name             = module.vnet.name
  master_subnet_id      = module.master-subnet.id
  worker_subnet_id      = module.worker-subnet.id

  encrypt               = true
}

output "id" {
  value = module.cluster.console_url
}

output "username" {
  value = module.cluster.username
}

output "password" {
  value = module.cluster.password
  sensitive = true
}

output "cluster_config" {
  value = module.cluster.config_file_path
}
