output "id" {
  value       = data.external.aro.result.id
  description = "ID of the cluster."
}

output "name" {
  value       = local.cluster_name
  description = "Name of the cluster."
}

output "resource_group_name" {
  value       = data.azurerm_resource_group.resource_group.name
  description = "Name of the resource group containing the cluster."
  depends_on  = [data.external.aro]
}

output "region" {
  value       = data.azurerm_resource_group.resource_group.location
  description = "Region containing the cluster."
  depends_on  = [data.external.aro]
}

output "config_file_path" {
  value       = module.oc_login.config_file_path
  description = "Path to the config file for the cluster."
}

output "token" {
  value = module.oc_login.token
  description = "CLI login token for cluster"
}

output "console_url" {
  value = data.external.aro.result.consoleUrl
  description = "URL of the cluster console"
}

output "username" {
  value = data.external.aro.result.kubeadminUsername
  description = "Login username"
}

output "password" {
  value = data.external.aro.result.kubeadminPassword
  description = "Login password"
  sensitive = true
}

output "serverURL" {
  value = data.external.aro.result.serverUrl
  description = "The url used to connect to the API of the cluster"
}

output "platform" {
  value = {
    id         = data.external.aro.result.id
    kubeconfig = module.oc_login.config_file_path
    server_url = data.external.aro.result.serverUrl
    type       = local.cluster_type
    type_code  = local.cluster_type_code
    version    = data.external.aro.result.version
    ingress    = local.ingress_hostname
    tls_secret = local.tls_secret
  }
  sensitive = true
  description = "Configuration values for the cluster platform"
}

output "sync" {
  value = local.cluster_name
  description = "Value used to sync downstream modules"
  depends_on  = [data.external.aro]
}

