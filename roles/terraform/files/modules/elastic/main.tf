terraform {
  required_version = ">= 1.0.0"

  required_providers {
    ec = {
      source = "elastic/ec"
      version = "0.4.0"
    }
    elasticstack = {
      source = "elastic/elasticstack"
      version = "0.3.3"
    }
  }
}

data "aws_secretsmanager_secret" "key_elastic_cloud" {
  name = "api_key_elastic_cloud_dm"
}

data "aws_secretsmanager_secret_version" "key_elastic_cloud_version" {
  secret_id = data.aws_secretsmanager_secret.key_elastic_cloud.id
}

provider "ec" {
  apikey = jsondecode(data.aws_secretsmanager_secret_version.key_elastic_cloud_version.secret_string)["api-key-elastic-cloud-dm"]
}

resource "ec_deployment" "crypto_dash" {
  
  name = "crypto-lake-elastic"
  region = "us-east-1"
  version = "8.15.3"
  deployment_template_id = "aws-storage-optimized"

  elasticsearch {
    topology {
      id = "hot_content"
      size = "4g"
      zone_count = 1 
    }
    autoscale = false
  }

  kibana {
    topology {
      size = "1g"
      zone_count = 1
    }
  }
  
}

output "elasticsearch_username" {
  value = ec_deployment.crypto_dash.elasticsearch_username
}

output "elasticsearch_password" {
  value = ec_deployment.crypto_dash.elasticsearch_password
  sensitive = true
}

output "kibana_endpoint" {
  value = ec_deployment.crypto_dash.kibana[0].https_endpoint
}