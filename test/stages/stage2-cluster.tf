module "cluster" {
  source = "./module"

  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  client_id = var.client_id
  client_secret = var.client_secret
  resource_group_name = var.resource_group_name
  region = var.region
  master_cidr = module.master_subnets.cidr_blocks[0]
  worker_cidr = module.worker_subnets.cidr_blocks[0]
  vpc_name = module.vpc.name
}


resource null_resource print_enabled {
  provisioner "local-exec" {
    command = "echo -n '${module.cluster.enabled}' > .enabled"
  }
}
