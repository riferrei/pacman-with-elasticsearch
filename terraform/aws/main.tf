###########################################
################## AWS ####################
###########################################

provider "aws" {
}

###########################################
############### Variables #################
###########################################

variable "es_endpoint" {
  type = string
}

variable "es_username" {
  type = string
}

variable "es_password" {
  type = string
}

variable "app_name" {
  type = string
  default = ""
}

variable "display_count" {
  type = number
  default = 10
}

variable "data_stream_enabled" {
  type = bool
  default = false
}

variable "transform_enabled" {
  type = bool
  default = false
}

variable "transform_frequency" {
  type = string
  default = "5s"
}

variable "transform_delay" {
  type = string
  default = "5m"
}

###########################################
################# Common ##################
###########################################

resource "random_string" "generated" {
  length = 8
  special = false
  upper = false
  lower = true
  number = false
}

data "template_file" "app_name" {
  template = length(var.app_name) > 0 ? var.app_name : random_string.generated.result
}

data "template_file" "input_data_index" {
  template = "pacman-input-data-${data.template_file.app_name.rendered}"
}

data "template_file" "scoreboard_index" {
  template = "pacman-scoreboard-${data.template_file.app_name.rendered}"
}

###########################################
################## Index ##################
###########################################

resource "null_resource" "index" {
  provisioner "local-exec" {
    command = "sh index-mgmt.sh"
    interpreter = ["bash", "-c"]
    working_dir = "../util"
    environment = {
      ES_ENDPOINT = var.es_endpoint
      ES_USERNAME = var.es_username
      ES_PASSWORD = var.es_password
      INPUT_DATA_INDEX = data.template_file.input_data_index.rendered
      SCOREBOARD_INDEX = data.template_file.scoreboard_index.rendered
      DATA_STREAM_ENABLED = var.data_stream_enabled
      TRANSFORM_ENABLED = var.transform_enabled
      TRANSFORM_FREQUENCY = var.transform_frequency
      TRANSFORM_DELAY = var.transform_delay
    }
  }
}
