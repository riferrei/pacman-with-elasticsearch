###########################################
################# Outputs #################
###########################################

output "Game" {
  value = "https://${google_storage_bucket.pacman.name}.storage.googleapis.com/index.html"
}

/****** Debugging the API Key *******

output "Debugging_ApiKey" {
  value = data.external.apikey.result
}

*************************************/