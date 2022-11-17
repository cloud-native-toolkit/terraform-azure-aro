provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = false
      purge_soft_delete_on_destroy = false
      purge_soft_deleted_keys_on_destroy = false
    }
  }

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}
