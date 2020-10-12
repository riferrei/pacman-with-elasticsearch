###########################################
################# Outputs #################
###########################################

output "Game" {
  value = "${azurerm_storage_account.pacman.primary_web_endpoint}index.html"
}

/****** Debugging the API Key *******

output "Debugging_ApiKey" {
  value = data.external.apikey.result
}

*************************************/
