###########################################
################# Bucket ##################
###########################################

resource "azurerm_storage_account" "pacman" {
  depends_on = [null_resource.index]
  name = replace(data.template_file.app_name.rendered, "-", "")
  resource_group_name = var.resource_group_name
  location = var.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"
  static_website {
    index_document = "index.html"
    error_404_document = "error.html"
  }
}

###########################################
################## HTML ###################
###########################################

resource "azurerm_storage_blob" "index" {
  name = "index.html"
  content_type = "text/html"
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  type = "Block"
  source = "../../content/index.html"
}

resource "azurerm_storage_blob" "error" {
  name = "error.html"
  content_type = "text/html"
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  type = "Block"
  source = "../../content/error.html"
}

resource "azurerm_storage_blob" "site" {
  name = "site.webmanifest"
  content_type = "application/manifest+json"
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  type = "Block"
  source = "../../content/site.webmanifest"
}

resource "azurerm_storage_blob" "start" {
  name = "start.html"
  content_type = "text/html"
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  type = "Block"
  source = "../../content/start.html"
}

resource "azurerm_storage_blob" "scoreboard" {
  name = "scoreboard.html"
  content_type = "text/html"
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  type = "Block"
  source = "../../content/scoreboard.html"
}

###########################################
################### CSS ###################
###########################################

resource "azurerm_storage_blob" "css_files" {
  for_each = fileset(path.module, "../../content/game/css/*.*")
  name = replace(each.key, "../../content/", "")
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  content_type = "text/css"
  type = "Block"
  source = each.value
}

###########################################
################### IMG ###################
###########################################

resource "azurerm_storage_blob" "img_files" {
  for_each = fileset(path.module, "../../content/game/img/*.*")
  name = replace(each.key, "../../content/", "")
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  content_type = "images/png"
  type = "Block"
  source = each.value
}

###########################################
################### JS ####################
###########################################

locals {
  js_files_raw = fileset(path.module, "../../content/game/js/*.*")
  js_files_mod = toset([
    for jsFile in local.js_files_raw:
      jsFile if jsFile != "../../content/game/js/shared.js"
  ])
}

resource "azurerm_storage_blob" "js_files" {
  for_each = local.js_files_mod
  name = replace(each.key, "../../content/", "")
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  content_type = "text/javascript"
  type = "Block"
  source = each.value
}

data "template_file" "apikey" {
  template = file("../../scripts/apikey.json")
  vars = {
    "input_data_index" = data.template_file.input_data_index.rendered
    "scoreboard_index" = data.template_file.scoreboard_index.rendered
  }
}

data "external" "apikey" {
  query = {
    es_endpoint = ec_deployment.elasticsearch.elasticsearch[0].https_endpoint
    es_username = ec_deployment.elasticsearch.elasticsearch_username
    es_password = ec_deployment.elasticsearch.elasticsearch_password
    api_key_body = data.template_file.apikey.rendered
  }
  program = ["sh", "../../scripts/apikey.sh" ]
}

data "template_file" "shared_js" {
  template = file("../../content/game/js/shared.js")
  vars = {
    es_endpoint = ec_deployment.elasticsearch.elasticsearch[0].https_endpoint
    authorization = "ApiKey ${base64encode(join(":", [data.external.apikey.result.apiID, data.external.apikey.result.apiKey]))}"
    input_data_index = data.template_file.input_data_index.rendered
    scoreboard_index = data.template_file.scoreboard_index.rendered
    transform_enabled = var.transform_enabled
    display_count = var.display_count
  }
}

resource "azurerm_storage_blob" "shared_js" {
  name = "game/js/shared.js"
  content_type = "text/javascript"
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  type = "Block"
  source_content = data.template_file.shared_js.rendered
}

###########################################
################# Sounds ##################
###########################################

resource "azurerm_storage_blob" "snd_files" {
  for_each = fileset(path.module, "../../content/game/sound/*.*")
  name = replace(each.key, "../../content/", "")
  storage_account_name = azurerm_storage_account.pacman.name
  storage_container_name = "$web"
  content_type = "audio/mpeg"
  type = "Block"
  source = each.value
}
