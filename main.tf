locals {
  tmp_dir = "${path.cwd}/.tmp/aro"
  name_prefix = var.name_prefix != null && var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  cluster_name = var.name != null && var.name != "" ? var.name : "${local.name_prefix}-${var.label}"
  vnet_id = data.azurerm_virtual_network.vnet.id
  id = data.external.aro.result.id
  cluster_config = "${path.cwd}/.kube/config" 
  cluster_type = "openshift"
  cluster_type_code = "ocp4"
  tls_secret = ""
  total_workers = var._count
  visibility = var.disable_public_endpoint ? "Private" : "Public"
  domain = "${random_string.cluster_domain_prefix.result}${random_string.cluster_domain.result}"
  ingress_hostname = lookup(data.external.aro.result, "publicSubdomain", "")
  console_url = lookup(data.external.aro.result, "consoleUrl", "")
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
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git?ref=v1.16.9"

  clis = ["jq"]
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'VNet name: ${var.vnet_name}'"
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

data azurerm_client_config default {
}

data azurerm_resource_group resource_group {
  depends_on = [null_resource.print_names]

  name = var.resource_group_name
}

data azurerm_virtual_network vnet {
  depends_on = [null_resource.print_names]

  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

# Following sets up disk ecnryption if required

locals {
    key_vault_name = var.key_vault_name == "" ? "${local.name_prefix}-vault" : var.key_vault_name
    create_vault   = var.encrypt && var.key_vault_name == "" ? true : false
}

resource "azurerm_key_vault" "key_vault" {
  count = local.create_vault ? 1 : 0

  name                        = local.key_vault_name
  location                    = data.azurerm_resource_group.resource_group.location
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  tenant_id                   = data.azurerm_client_config.default.tenant_id
  sku_name                    = "premium"
  soft_delete_retention_days  = 7
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
}

data "azurerm_key_vault" "key_vault" {
  count = local.create_vault ? 0 : 1

  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_key_vault_access_policy" "user" {
  count = var.encrypt ? 1 : 0

  key_vault_id  = local.create_vault ? azurerm_key_vault.key_vault[0].id : data.azurerm_key_vault.key_vault[0].id
  tenant_id     = data.azurerm_client_config.default.tenant_id
  object_id     = data.azurerm_client_config.default.object_id

  key_permissions = [ 
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign"
  ]
}

resource "azurerm_key_vault_key" "encryption_key" {
  depends_on = [azurerm_key_vault_access_policy.user]
  count = var.encrypt ? 1 : 0

  name          = "${local.cluster_name}-key"
  key_vault_id  = local.create_vault ? azurerm_key_vault.key_vault[0].id : data.azurerm_key_vault.key_vault[0].id
  key_type      = "RSA"
  key_size      = "2048"

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
}

resource "azurerm_disk_encryption_set" "aro" {
  count = var.encrypt ? 1 : 0

  name                  = "${local.cluster_name}-des"
  resource_group_name   = data.azurerm_resource_group.resource_group.name
  location              = data.azurerm_resource_group.resource_group.location
  key_vault_key_id      = azurerm_key_vault_key.encryption_key[0].id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault_access_policy" "aro-disk" {
  count = var.encrypt ? 1 : 0

  key_vault_id  = local.create_vault ? azurerm_key_vault.key_vault[0].id : data.azurerm_key_vault.key_vault[0].id
  tenant_id     = azurerm_disk_encryption_set.aro[0].identity.0.tenant_id
  object_id     = azurerm_disk_encryption_set.aro[0].identity.0.principal_id

  key_permissions = [ 
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "azurerm_role_assignment" "aro-disk" {
  count = var.encrypt ? 1 : 0

  scope = local.create_vault ? azurerm_key_vault.key_vault[0].id : data.azurerm_key_vault.key_vault[0].id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id = azurerm_disk_encryption_set.aro[0].identity.0.principal_id
}

# Following deploys the ARO cluster
resource null_resource aro {
  count = var.provision ? 1 : 0
  depends_on = [
    data.azurerm_virtual_network.vnet,
    azurerm_key_vault_access_policy.aro-disk
  ]

  triggers = {
    bin_dir             = module.setup_clis.bin_dir
    subscription_id     = var.subscription_id
    resource_group_name = data.azurerm_resource_group.resource_group.name
    cluster_name        = local.cluster_name
    tenant_id           = var.tenant_id
    client_id           = var.client_id
    client_secret       = var.client_secret
    disk_encryption_set = var.encrypt ? azurerm_disk_encryption_set.aro[0].id : null
    encrypt             = var.encrypt
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-cluster.sh '${self.triggers.subscription_id}' '${self.triggers.resource_group_name}' '${self.triggers.cluster_name}' '${var.region}' '${local.vnet_id}' '${var.master_subnet_id}' '${var.worker_subnet_id}' '${local.domain}'"

    environment = {
      BIN_DIR = self.triggers.bin_dir
      TMP_DIR = local.tmp_dir
      TENANT_ID = self.triggers.tenant_id
      CLIENT_ID = self.triggers.client_id
      CLIENT_SECRET = nonsensitive(self.triggers.client_secret)
      VM_SIZE = var.flavor
      MASTER_VM_SIZE = var.master_flavor
      OS_TYPE = var.os_type
      WORKER_COUNT = var._count
      REGION = var.region
      VISIBILITY = local.visibility
      DISK_SIZE = var.disk_size
      PULL_SECRET = local.pull_secret
      ENCRYPT = self.triggers.encrypt
      DES = self.triggers.disk_encryption_set
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

data "external" "aro" {
  depends_on = [null_resource.aro]

  program = ["bash", "${path.module}/scripts/get-cluster.sh"]

  query = {
    tmp_dir             = local.tmp_dir
    bin_dir             = module.setup_clis.bin_dir
    cluster_name        = local.cluster_name
    resource_group_name = data.azurerm_resource_group.resource_group.name
    subscription_id     = var.subscription_id
    tenant_id           = var.tenant_id
    client_id           = var.client_id
    client_secret       = nonsensitive(var.client_secret)
    access_token        = ""
  }
}

# Wait time added to allow for cluster operators to finish deloying
resource "time_sleep" "wait_for_cluster" {
  depends_on = [
    data.external.aro
  ]

  create_duration = "2m"
}

data "external" "login" {
  program = ["bash","${path.module}/scripts/login-cluster.sh"]

  query = {
    bin_dir     = module.setup_clis.bin_dir
    kubeconfig  = local.cluster_config
    username    = data.external.aro.result.kubeadminUsername
    password    = data.external.aro.result.kubeadminPassword
    server_url  = data.external.aro.result.serverUrl
  }
}

