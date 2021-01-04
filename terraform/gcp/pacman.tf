###########################################
################# Bucket ##################
###########################################

resource "google_storage_bucket" "pacman" {
  depends_on = [null_resource.index]
  name = data.template_file.app_name.rendered
  provider = google
  location = "US"
  website {
    main_page_suffix = "index.html"
    not_found_page = "error.html"
  }
}

resource "google_storage_bucket_access_control" "pacman" {
  bucket = google_storage_bucket.pacman.name
  role = "READER"
  entity = "allUsers"
}

###########################################
################## HTML ###################
###########################################

resource "google_storage_bucket_object" "index" {
  bucket = google_storage_bucket.pacman.name
  name = "index.html"
  content_type = "text/html"
  source = "../../content/index.html"
}

resource "google_storage_object_acl" "index" {
  bucket = google_storage_bucket.pacman.name
  object = google_storage_bucket_object.index.output_name
  role_entity = ["READER:allUsers"]
}

resource "google_storage_bucket_object" "error" {
  bucket = google_storage_bucket.pacman.name
  name = "error.html"
  content_type = "text/html"
  source = "../../content/error.html"
}

resource "google_storage_object_acl" "error" {
  bucket = google_storage_bucket.pacman.name
  object = google_storage_bucket_object.error.output_name
  role_entity = ["READER:allUsers"]
}

resource "google_storage_bucket_object" "scoreboard" {
  bucket = google_storage_bucket.pacman.name
  name = "scoreboard.html"
  content_type = "text/html"
  source = "../../content/scoreboard.html"
}

resource "google_storage_object_acl" "scoreboard" {
  bucket = google_storage_bucket.pacman.name
  object = google_storage_bucket_object.scoreboard.output_name
  role_entity = ["READER:allUsers"]
}

resource "google_storage_bucket_object" "site" {
  bucket = google_storage_bucket.pacman.name
  name = "site.webmanifest"
  content_type = "application/manifest+json"
  source = "../../content/site.webmanifest"
}

resource "google_storage_object_acl" "site" {
  bucket = google_storage_bucket.pacman.name
  object = google_storage_bucket_object.site.output_name
  role_entity = ["READER:allUsers"]
}

resource "google_storage_bucket_object" "start" {
  bucket = google_storage_bucket.pacman.name
  name = "start.html"
  content_type = "text/html"
  source = "../../content/start.html"
}

resource "google_storage_object_acl" "start" {
  bucket = google_storage_bucket.pacman.name
  object = google_storage_bucket_object.start.output_name
  role_entity = ["READER:allUsers"]
}

###########################################
################### CSS ###################
###########################################

resource "google_storage_bucket_object" "css_files" {
  for_each = fileset(path.module, "../../content/game/css/*.*")
  bucket = google_storage_bucket.pacman.name
  name = replace(each.key, "../../content/", "")
  content_type = "text/css"
  source = each.value
}

resource "google_storage_object_acl" "css_files" {
  for_each = google_storage_bucket_object.css_files
  bucket = google_storage_bucket.pacman.name
  object = each.value.output_name
  role_entity = ["READER:allUsers"]
}

###########################################
################### IMG ###################
###########################################

resource "google_storage_bucket_object" "img_files" {
  for_each = fileset(path.module, "../../content/game/img/*.*")
  bucket = google_storage_bucket.pacman.name
  name = replace(each.key, "../../content/", "")
  content_type = "images/png"
  source = each.value
}

resource "google_storage_object_acl" "img_files" {
  for_each = google_storage_bucket_object.img_files
  bucket = google_storage_bucket.pacman.name
  object = each.value.output_name
  role_entity = ["READER:allUsers"]
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

resource "google_storage_bucket_object" "js_files" {
  for_each = local.js_files_mod
  bucket = google_storage_bucket.pacman.name
  name = replace(each.key, "../../content/", "")
  content_type = "text/javascript"
  source = each.value
}

resource "google_storage_object_acl" "js_files" {
  for_each = google_storage_bucket_object.js_files
  bucket = google_storage_bucket.pacman.name
  object = each.value.output_name
  role_entity = ["READER:allUsers"]
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

resource "google_storage_bucket_object" "shared_js" {
  depends_on = [google_storage_bucket_object.js_files]
  bucket = google_storage_bucket.pacman.name
  name = "game/js/shared.js"
  content_type = "text/javascript"
  content = data.template_file.shared_js.rendered
}

resource "google_storage_object_acl" "shared_js" {
  bucket = google_storage_bucket.pacman.name
  object = google_storage_bucket_object.shared_js.output_name
  role_entity = ["READER:allUsers"]
}

###########################################
################# Sounds ##################
###########################################

resource "google_storage_bucket_object" "snd_files" {
  for_each = fileset(path.module, "../../content/game/sound/*.*")
  bucket = google_storage_bucket.pacman.name
  name = replace(each.key, "../../content/", "")
  content_type = "audio/mpeg"
  source = each.value
}

resource "google_storage_object_acl" "snd_files" {
  for_each = google_storage_bucket_object.snd_files
  bucket = google_storage_bucket.pacman.name
  object = each.value.output_name
  role_entity = ["READER:allUsers"]
}
