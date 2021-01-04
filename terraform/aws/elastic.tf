terraform {
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "0.1.0-beta"
    }
  }
}

resource "ec_deployment" "elasticsearch" {
  name = data.template_file.app_name.rendered
  deployment_template_id = "aws-io-optimized-v2"
  region = var.ec_region
  version = "7.10.1"
  elasticsearch {
    topology {
      size = "8g"
      zone_count = "2"
    }
    config {
      user_settings_yaml = <<EOF
      http.cors.enabled : true
      http.cors.allow-origin : "*"
      http.cors.allow-methods : OPTIONS, HEAD, GET, POST, PUT, DELETE
      http.cors.allow-headers : "*"
      EOF
    }
  }
  kibana {
    topology {
      size = "2g"
      zone_count = "2"
    }
  }
}
