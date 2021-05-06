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
  deployment_template_id = "azure-io-optimized"
  // The expression below is a workaround until
  // the Elastic Cloud TF provider learns how to
  // automatically pick up the region template
  // based on the cloud provider region.
  region = "azure-${var.ec_region}"
  version = "7.12.1"
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
