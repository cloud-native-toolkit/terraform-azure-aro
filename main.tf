locals {
  tmp_dir = "${path.cwd}/.tmp/aro"
  name_prefix = var.name_prefix != null && var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  cluster_name = var.name != null && var.name != "" ? var.name : "${local.name_prefix}-${var.label}"
  vnet_id = data.azurerm_virtual_network.vnet.id
  id = data.external.aro.result.id
  cluster_config = "${path.cwd}/.kube/config"
  cluster_type = "openshift"
  cluster_type_code = "ocp4"
  cluster_version = var.openshift_version
  tls_secret = ""
  total_workers = var._count
  visibility = var.disable_public_endpoint ? "Private" : "Public"
  domain = "${random_string.cluster_domain_prefix.result}${random_string.cluster_domain.result}"
  server_url = lookup(data.external.aro.result, "serverUrl", "")
  ingress_hostname = lookup(data.external.aro.result, "publicSubdomain", "")
  console_url = lookup(data.external.aro.result, "consoleUrl", "")
  username = lookup(data.external.aro.result, "kubeadminUsername", "")
  password = lookup(data.external.aro.result, "kubeadminPassword", "")
  aro_data = jsonencode({
    tmp_dir             = local.tmp_dir
    bin_dir             = module.setup_clis.bin_dir
    cluster_name        = local.cluster_name
    resource_group_name = var.resource_group_name
    subscription_id     = var.subscription_id
    tenant_id           = var.tenant_id
    client_id           = var.client_id
    client_secret       = nonsensitive(var.client_secret)
    access_token        = ""
  })
  pull_secret = var.pull_secret_file != "" ? file(var.pull_secret_file) : var.pull_secret
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["jq"]
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
  provisioner "local-exec" {
    command = "echo 'Resource group name: ${var.resource_group_name}'"
  }
}

resource random_string cluster_domain_prefix {
  length = 1
  special = false
  upper = false
  lower = true
  number = false
}

resource random_string cluster_domain {
  length = 7
  special = false
  upper = false
  lower = true
  number = true
}

module "cluster_rg" {
  source = "github.com/cloud-native-toolkit/terraform-azure-resource-group"
  count = var.provision ? 1 : 0

  resource_group_name = "aro-${local.domain}"
  region              = var.region
}

data azurerm_client_config default {
}

data azurerm_virtual_network vnet {
  depends_on = [null_resource.print_names]

  name                = var.vpc_name
  resource_group_name = var.resource_group_name
}

resource azurerm_role_assignment network_contributor {
  count = var.provision ? 1 : 0

  scope                = data.azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = var.openshift_resource_provider_id
}

resource null_resource aro {
  count = var.provision ? 1 : 0
  depends_on = [azurerm_role_assignment.network_contributor]

  triggers = {
    bin_dir = module.setup_clis.bin_dir
    subscription_id = var.subscription_id
    resource_group_name = var.resource_group_name
    resource_group_id = module.cluster_rg[0].id
    cluster_name = local.cluster_name
    tenant_id = var.tenant_id
    client_id = var.client_id
    client_secret = var.client_secret
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-cluster.sh '${self.triggers.subscription_id}' '${self.triggers.resource_group_name}' '${self.triggers.resource_group_id}' '${self.triggers.cluster_name}' '${var.region}' '${local.vnet_id}' '${var.master_subnet_id}' '${var.worker_subnet_id}' '${local.domain}'"

    environment = {
      BIN_DIR = self.triggers.bin_dir
      TMP_DIR = local.tmp_dir
      TENANT_ID = self.triggers.tenant_id
      CLIENT_ID = self.triggers.client_id
      CLIENT_SECRET = nonsensitive(self.triggers.client_secret)
      OPENSHIFT_VERSION = var.openshift_version
      VM_SIZE = var.flavor
      MASTER_VM_SIZE = var.master_flavor
      OS_TYPE = var.os_type
      WORKER_COUNT = var._count
      AUTH_GROUP_ID= var.auth_group_id
      REGION = var.region
      VISIBILITY = local.visibility
      DISK_SIZE = var.disk_size
      PULL_SECRET = local.pull_secret
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${path.module}/scripts/destroy-cluster.sh '${self.triggers.subscription_id}' '${self.triggers.resource_group_name}' '${self.triggers.cluster_name}'"

    environment = {
      BIN_DIR = self.triggers.bin_dir
      TENANT_ID = self.triggers.tenant_id
      CLIENT_ID = self.triggers.client_id
      CLIENT_SECRET = nonsensitive(self.triggers.client_secret)
    }
  }
}

resource null_resource aro_info {
  depends_on = [null_resource.aro]

  provisioner "local-exec" {
    command = "echo '${local.aro_data}' | ${path.module}/scripts/get-cluster.sh"
  }
}

data external aro {
  depends_on = [null_resource.aro, null_resource.aro_info]

  program = ["bash", "${path.module}/scripts/get-cluster.sh"]

  query = {
    tmp_dir = local.tmp_dir
    bin_dir = module.setup_clis.bin_dir
    cluster_name = local.cluster_name
    resource_group_name = var.resource_group_name
    subscription_id = var.subscription_id
    tenant_id = var.tenant_id
    client_id = var.client_id
    client_secret = nonsensitive(var.client_secret)
    access_token = ""
  }
}

resource null_resource oc_login {
  depends_on = [data.external.aro]

  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/login-cluster.sh '${local.server_url}' '${local.username}'"

    environment = {
      PASSWORD = local.password
      KUBECONFIG = local.cluster_config
    }
  }
}
