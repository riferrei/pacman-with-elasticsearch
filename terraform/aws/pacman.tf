###########################################
################# Bucket ##################
###########################################

resource "aws_s3_bucket" "pacman" {
  depends_on = [null_resource.index]
  bucket = data.template_file.app_name.rendered
  acl = "public-read"
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["*"]
  }
  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${data.template_file.app_name.rendered}/*"
        }
    ]
}
EOF
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

###########################################
################## HTML ###################
###########################################

resource "aws_s3_bucket_object" "index" {
  bucket = aws_s3_bucket.pacman.bucket
  key = "index.html"
  content_type = "text/html"
  source = "../../content/index.html"
}

resource "aws_s3_bucket_object" "error" {
  bucket = aws_s3_bucket.pacman.bucket
  key = "error.html"
  content_type = "text/html"
  source = "../../content/error.html"
}

resource "aws_s3_bucket_object" "start" {
  bucket = aws_s3_bucket.pacman.bucket
  key = "start.html"
  content_type = "text/html"
  source = "../../content/start.html"
}

resource "aws_s3_bucket_object" "webmanifest" {
  bucket = aws_s3_bucket.pacman.bucket
  key = "site.webmanifest"
  content_type = "application/manifest+json"
  source = "../../content/site.webmanifest"
}

resource "aws_s3_bucket_object" "scoreboard" {
  bucket = aws_s3_bucket.pacman.bucket
  key = "scoreboard.html"
  content_type = "text/html"
  source = "../../content/scoreboard.html"
}

###########################################
################### CSS ###################
###########################################

resource "aws_s3_bucket_object" "css_files" {
  for_each = fileset(path.module, "../../content/game/css/*.*")
  bucket = aws_s3_bucket.pacman.bucket
  key = replace(each.key, "../../content/", "")
  content_type = "text/css"
  source = each.value
}

###########################################
################### IMG ###################
###########################################

resource "aws_s3_bucket_object" "img_files" {
  for_each = fileset(path.module, "../../content/game/img/*.*")
  bucket = aws_s3_bucket.pacman.bucket
  key = replace(each.key, "../../content/", "")
  content_type = "images/png"
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

resource "aws_s3_bucket_object" "js_files" {
  for_each = local.js_files_mod
  bucket = aws_s3_bucket.pacman.bucket
  key = replace(each.key, "../../content/", "")
  content_type = "text/javascript"
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
    es_endpoint = module.elastic.elasticsearch_endpoint
    es_username = module.elastic.elasticsearch_username
    es_password = module.elastic.elasticsearch_password
    api_key_body = data.template_file.apikey.rendered
  }
  program = ["sh", "../../scripts/apikey.sh" ]
}

data "template_file" "shared_js" {
  template = file("../../content/game/js/shared.js")
  vars = {
    es_endpoint = module.elastic.elasticsearch_endpoint
    authorization = "ApiKey ${base64encode(join(":", [data.external.apikey.result.apiID, data.external.apikey.result.apiKey]))}"
    input_data_index = data.template_file.input_data_index.rendered
    scoreboard_index = data.template_file.scoreboard_index.rendered
    transform_enabled = var.transform_enabled
    display_count = var.display_count
  }
}

resource "aws_s3_bucket_object" "shared_js" {
  depends_on = [aws_s3_bucket_object.js_files]
  bucket = aws_s3_bucket.pacman.bucket
  key = "game/js/shared.js"
  content_type = "text/javascript"
  content = data.template_file.shared_js.rendered
}

###########################################
################# Sounds ##################
###########################################

resource "aws_s3_bucket_object" "snd_files" {
  for_each = fileset(path.module, "../../content/game/sound/*.*")
  bucket = aws_s3_bucket.pacman.bucket
  key = replace(each.key, "../../content/", "")
  content_type = "audio/mpeg"
  source = each.value
}
