###########################################
################# Outputs #################
###########################################

output "Game" {
  value = "http://${aws_s3_bucket.pacman.website_endpoint}/index.html"
}

/****** Debugging the API Key *******

output "Debugging_ApiKey" {
  value = data.external.apikey.result
}

*************************************/