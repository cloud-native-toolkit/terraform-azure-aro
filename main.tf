locals {
  tmp_dir = "${path.cwd}/.tmp/aro"
  name_prefix = var.name_prefix != null && var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  cluster_name = var.name != null && var.name != "" ? var.name : "${local.name_prefix}-${var.label}"
  aro_rg = "/subscriptions/${data.azurerm_client_config.default.subscription_id}/resourceGroups/${local.name_prefix}-aro"
  vnet_id = data.azurerm_virtual_network.vnet.id
  id = data.external.aro.result.id 
  cluster_type = "openshift"
  cluster_type_code = "ocp4"
  tls_secret = ""
  visibility = var.disable_public_endpoint ? "Private" : "Public"
  domain = "${random_string.cluster_domain_prefix.result}${random_string.cluster_domain.result}"
  ingress_hostname = lookup(data.external.aro.result, "publicSubdomain", "")
  console_url = lookup(data.external.aro.result, "consoleUrl", "")
  pull_secret = var.pull_secret_file != "" ? file(var.pull_secret_file) : var.pull_secret
  sp_name = "${local.name_prefix}-aro-${local.domain}-sp"
  sp_data_file = "${data.external.tmp_dir.result.path}/app-service-principal.json"
  rp_data_file = "${data.external.tmp_dir.result.path}/aro-resource-provider.json"

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

# Create tmp dir if not already in place
data "external" "tmp_dir" {
  program = ["bash","${path.module}/scripts/create-tmp-dir.sh"]

  query = {
    tmp_dir = local.tmp_dir
  }
}

# Login to az cli if not already
resource "null_resource" "az_login" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/az-login.sh"

    environment = {
      CLIENT_ID       = data.azurerm_client_config.default.client_id
      TENANT_ID       = data.azurerm_client_config.default.tenant_id
      SUBSCRIPTION_ID = data.azurerm_client_config.default.subscription_id
      CLIENT_SECRET   = var.client_secret
      OUTPUT          = "${data.external.tmp_dir.result.path}/account.json"
     }
  }
}

data "external" "aro_rp" {
  depends_on = [
    null_resource.az_login
  ]
  program = ["bash","${path.module}/scripts/get-ocp-rp-id.sh"]

  query = {
    rp_data_file  = local.rp_data_file
  }
}

# Create service principal
resource "null_resource" "service_principal" {
  depends_on = [
    null_resource.az_login
  ]
  triggers = {
    sp_name       = local.sp_name
    sp_data_file  = local.sp_data_file
    bin_dir       = module.setup_clis.bin_dir
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-sp.sh"

    environment = {
      SP_NAME   = self.triggers.sp_name 
      BIN_DIR   = self.triggers.bin_dir
      OUT_FILE  = self.triggers.sp_data_file
     }
  }

  provisioner "local-exec" {
    when = destroy

    command = "${path.module}/scripts/delete-sp.sh" 

    environment = {
      BIN_DIR   = self.triggers.bin_dir
      SP_FILE   = self.triggers.sp_data_file
    } 
  }
}

data "external" "sp_data" {
  depends_on = [
    null_resource.service_principal
  ]

  program = ["bash", "${path.module}/scripts/read-sp-details.sh"]

  query = {
    bin_dir       = module.setup_clis.bin_dir
    sp_data_file  = local.sp_data_file
  }
}

# Create role assignments
resource "azurerm_role_assignment" "sp_user_administrator" {
  scope                 = data.azurerm_resource_group.resource_group.id
  role_definition_name  = "User Access Administrator"
  principal_id          = data.external.sp_data.result.id
}

resource "azurerm_role_assignment" "sp_contributor" {
  scope                 = data.azurerm_resource_group.resource_group.id
  role_definition_name  = "Contributor"
  principal_id          = data.external.sp_data.result.id
}

resource "azurerm_role_assignment" "aro_cluster_service_principal_network_contributor" {
  scope                 = data.azurerm_virtual_network.vnet.id
  role_definition_name  = "Contributor"
  principal_id          = data.external.sp_data.result.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aro_resource_provider_service_principal_network_contributor" {
  scope                 = data.azurerm_virtual_network.vnet.id
  role_definition_name  = "Contributor"
  principal_id          = data.external.aro_rp.result.id
  skip_service_principal_aad_check = true
}

# Create cluster
resource "azapi_resource" "aro_cluster" {
  depends_on = [
    azurerm_role_assignment.sp_user_administrator,
    azurerm_role_assignment.sp_contributor,
    azurerm_role_assignment.aro_resource_provider_service_principal_network_contributor,
    azurerm_role_assignment.aro_cluster_service_principal_network_contributor
  ]
  name = local.cluster_name
  location = data.azurerm_resource_group.resource_group.location
  parent_id = data.azurerm_resource_group.resource_group.id
  type = "Microsoft.RedHatOpenShift/openShiftClusters@2022-04-01"
  tags = var.tags

  body = jsonencode({
    properties = {
      servicePrincipalProfile = {
        clientId              = data.external.sp_data.result.client_id
        clientSecret          = data.external.sp_data.result.client_secret
      }
      clusterProfile = {
        domain                = local.domain
        fipsValidatedModules  = var.fips ? "Enabled" : "Disabled"
        resourceGroupId       = local.aro_rg
        pullSecret            = local.pull_secret
      }
      networkProfile = {
        podCidr               = var.pod_cidr
        serviceCidr           = var.service_cidr
      }
      masterProfile = {
        vmSize                = var.master_flavor
        subnetId              = var.master_subnet_id
        encryptionAtHost      = var.encrypt ? "Enabled" : "Disabled"
      }
      workerProfiles = [{
        name                  = "worker"
        vmSize                = var.worker_flavor
        subnetId              = var.worker_subnet_id
        count                 = var.worker_count
        diskSizeGB            = var.worker_disk_size
        encryptionAtHost      = var.encrypt ? "Enabled" : "Disabled"
      }]
      apiserverProfile = {
        visibility            = var.disable_public_endpoint ? "Private" : "Public"
      }
      ingressProfiles = [{
        name                  = "default"
        visibility            = var.disable_public_endpoint ? "Private" : "Public"
      }]
    }
  })

  lifecycle {
    ignore_changes = [
      tags, body
    ]
  }

  timeouts {
    create = "60m"
    delete = "30m"
  }
}

data "external" "aro" {
  depends_on = [azapi_resource.aro_cluster]

  program = ["bash", "${path.module}/scripts/get-cluster.sh"]

  query = {
    tmp_dir             = local.tmp_dir
    bin_dir             = module.setup_clis.bin_dir
    cluster_name        = local.cluster_name
    resource_group_name = data.azurerm_resource_group.resource_group.name
    subscription_id     = data.azurerm_client_config.default.subscription_id
    tenant_id           = data.azurerm_client_config.default.tenant_id
    client_id           = data.external.sp_data.result.client_id
    client_secret       = data.external.sp_data.result.client_secret
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

module "oc_login" {
  source = "github.com/cloud-native-toolkit/terraform-ocp-login.git?ref=v1.6.0"

  server_url      = data.external.aro.result.serverUrl
  login_user      = data.external.aro.result.kubeadminUsername
  login_password  = data.external.aro.result.kubeadminPassword
  login_token     = ""
}