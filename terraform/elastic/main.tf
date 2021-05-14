terraform {
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "0.1.0-beta"
    }
  }
}

variable "deployment_name" {
  type = string
}

variable "deployment_template_id" {
  type = string
}

variable "cloud_region" {
  type = string
}

resource "ec_deployment" "elasticsearch" {
  name = var.deployment_name
  deployment_template_id = var.deployment_template_id
  region = var.cloud_region
  version = "7.12.1"
  elasticsearch {
    topology {
      size = "8g"
      zone_count = "2"
    }
    config {
      user_settings_yaml = file("${path.module}/settings.yaml")
    }
  }
  kibana {
    topology {
      size = "2g"
      zone_count = "2"
    }
  }
}

output "elasticsearch_endpoint" {
  value = ec_deployment.elasticsearch.elasticsearch[0].https_endpoint
}

output "kibana_endpoint" {
  value = ec_deployment.elasticsearch.kibana[0].https_endpoint
}

output "elasticsearch_username" {
  value = ec_deployment.elasticsearch.elasticsearch_username
}

output "elasticsearch_password" {
  value = ec_deployment.elasticsearch.elasticsearch_password
  sensitive = true
}
