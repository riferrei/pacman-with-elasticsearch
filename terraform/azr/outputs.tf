###########################################
################# Outputs #################
###########################################

output "Game" {
  value = "${azurerm_storage_account.pacman.primary_web_endpoint}index.html"
}

output "Kibana" {
  value = ec_deployment.elasticsearch.kibana[0].https_endpoint
}

output "Username" {
  value = ec_deployment.elasticsearch.elasticsearch_username
}

output "Password" {
  value = ec_deployment.elasticsearch.elasticsearch_password
  sensitive = true
}

/****** Debugging the API Key *******

output "Debugging_ApiKey" {
  value = data.external.apikey.result
}

*************************************/
