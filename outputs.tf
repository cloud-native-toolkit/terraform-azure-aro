# output "id" {
#   value       = data.external.aro.result.id
#   description = "ID of the cluster."
# }

# output "name" {
#   value       = local.cluster_name
#   description = "Name of the cluster."
# }

# output "resource_group_name" {
#   value       = var.resource_group_name
#   description = "Name of the resource group containing the cluster."
#   depends_on  = [data.external.aro]
# }

# output "region" {
#   value       = var.region
#   description = "Region containing the cluster."
#   depends_on  = [data.external.aro]
# }

# output "config_file_path" {
#   value       = local.cluster_config
#   description = "Path to the config file for the cluster."
#   depends_on  = [data.external.login]
# }

# output "token" {
#   value = data.external.login.result.token
#   description = "CLI login token for cluster"
# }

# output "username" {
#   value = data.external.aro.result.kubeadminUsername
#   description = "Login username"
# }

# output "password" {
#   value = data.external.aro.result.kubeadminPassword
#   description = "Login password"
#   sensitive = true
# }

# output "serverURL" {
#   value = data.external.aro.result.serverUrl
#   description = "The url used to connect to the API of the cluster"
# }

# output "platform" {
#   value = {
#     id         = data.external.aro.result.id
#     kubeconfig = local.cluster_config
#     server_url = data.external.aro.result.serverUrl
#     type       = local.cluster_type
#     type_code  = local.cluster_type_code
#     # version    = local.cluster_version    # This needs to be added to the data query on the cluster
#     ingress    = local.ingress_hostname
#     tls_secret = local.tls_secret
#   }
#   sensitive = true
#   description = "Configuration values for the cluster platform"
#   depends_on  = [data.external.login]
# }

# output "sync" {
#   value = local.cluster_name
#   description = "Value used to sync downstream modules"
#   depends_on  = [data.external.aro]
# }

