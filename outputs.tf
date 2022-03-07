output "id" {
  value       = data.external.aro.result.id
  description = "ID of the cluster."
}

output "name" {
  value       = local.cluster_name
  description = "Name of the cluster."
}

output "resource_group_name" {
  value       = var.resource_group_name
  description = "Name of the resource group containing the cluster."
  depends_on  = [data.external.aro]
}

output "region" {
  value       = var.region
  description = "Region containing the cluster."
  depends_on  = [data.external.aro]
}

output "config_file_path" {
  value       = local.cluster_config
  description = "Path to the config file for the cluster."
  depends_on  = [data.external.oc_login]
}

output "platform" {
  value = {
    id         = data.external.aro.result.id
    kubeconfig = local.cluster_config
    server_url = data.external.aro.result.serverUrl
    type       = local.cluster_type
    type_code  = local.cluster_type_code
    version    = local.cluster_version
    ingress    = local.ingress_hostname
    tls_secret = local.tls_secret
  }
  sensitive = true
  description = "Configuration values for the cluster platform"
  depends_on  = [data.external.oc_login]
}

output "sync" {
  value = local.cluster_name
  description = "Value used to sync downstream modules"
  depends_on  = [data.external.aro]
}

output "total_worker_count" {
  description = "The total number of workers for the cluster. (subnets * number of workers)"
  value = local.total_workers
  depends_on  = [data.external.aro]
}
