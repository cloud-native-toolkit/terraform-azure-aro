locals {
  tmp_dir = "${path.cwd}/.tmp/aro"
  name_prefix = var.name_prefix != null && var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  cluster_name = var.name != null && var.name != "" ? var.name : "${local.name_prefix}-cluster"
  vnet_id = data.azurerm_virtual_network.vnet.id
  id = data.external.aro.result.id
  cluster_config = ""
  server_url = lookup(lookup(data.external.aro.result, "properties", {fqdn = ""}), "fqdn", "")
  ingress_hostname = lookup(lookup(data.external.aro.result, "routerProfiles", {publicSubdomain = ""}), "publicSubdomain", "")
  cluster_type = "openshift"
  cluster_type_code = "ocp4"
  cluster_version = var.openshift_version
  tls_secret = ""
  total_workers = var.infra_count + var._count
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["jq"]
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
}

data azurerm_virtual_network vnet {
  depends_on = [null_resource.print_names]

  name                = var.vpc_name
  resource_group_name = var.resource_group_name
}

resource null_resource aro {
  count = var.provision ? 1 : 0

  triggers = {
    subscription_id = var.subscription_id
    resource_group_name = var.resource_group_name
    cluster_name = local.cluster_name
    tenant_id = var.tenant_id
    client_id = var.client_id
    client_secret = var.client_secret
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-cluster.sh '${self.triggers.subscription_id}' '${self.triggers.resource_group_name}' '${self.triggers.cluster_name}' '${var.region}' '${local.vnet_id}' '${var.master_cidr}' '${var.worker_cidr}'"

    environment = {
      TMP_DIR = local.tmp_dir
      TENANT_ID = self.triggers.tenant_id
      CLIENT_ID = self.triggers.client_id
      CLIENT_SECRET = self.triggers.client_secret
      OPENSHIFT_VERSION = var.openshift_version
      VM_SIZE = var.flavor
      MASTER_SIZE = var.master_flavor
      OS_TYPE = var.os_type
      MASTER_COUNT = var.master_count
      INFRA_COUNT = var.infra_count
      COMPUTE_COUNT = var._count
      AUTH_GROUP_ID= var.auth_group_id
      REGION = var.region
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${path.module}/scripts/destroy-cluster.sh '${self.triggers.subscription_id}' '${self.triggers.resource_group_name}' '${self.triggers.cluster_name}'"

    environment = {
      TENANT_ID = self.triggers.tenant_id
      CLIENT_ID = self.triggers.client_id
      CLIENT_SECRET = self.triggers.client_secret
    }
  }
}

data external aro {
  depends_on = [null_resource.aro]

  program = ["bash", "${path.module}/get-cluster.sh"]

  query = {
    bin_dir = module.setup_clis.bin_dir
    cluster_name = local.cluster_name
    resource_group_name = var.resource_group_name
    subscription_id = var.subscription_id
    tenant_id = var.tenant_id
    client_id = var.client_id
    client_secret = var.client_secret
  }
}
