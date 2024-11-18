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

variable "dir_raiz_els" {
  type = string
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
      zone_count = 2
    }
    autoscale = false
  }
  kibana {
    topology {
      size = "1g"
      zone_count = 2
    }
  }
}

output "elasticsearch_resource_id" {
  value = ec_deployment.crypto_dash.elasticsearch[0].resource_id
}

output "elasticsearch_region" {
  value = ec_deployment.crypto_dash.elasticsearch[0].region
}

output "kibana_endpoint" {
  value = ec_deployment.crypto_dash.kibana[0].https_endpoint
}

output "elasticsearch_password" {
  value = ec_deployment.crypto_dash.elasticsearch_password
  sensitive = true
}

resource "null_resource" "atualiza_elasticsearch" {
  provisioner "local-exec" {
    command = <<EOT
      INVENTORY_FILE="${var.dir_raiz_els}/inventory.ini"

      # Atualiza o valor do node do Elastic com o output do Terraform
      sed -i 's|^elasticsearch_nodes=.*|elasticsearch_nodes="${ec_deployment.crypto_dash.elasticsearch[0].resource_id}.${ec_deployment.crypto_dash.elasticsearch[0].region}.aws.found.io"|' $INVENTORY_FILE && \
      
      # Atualiza o valor do endpoint do Kibana com o output do Terraform
      sed -i 's|^kibana_endpoint=.*|kibana_endpoint="${ec_deployment.crypto_dash.kibana[0].https_endpoint}"|' $INVENTORY_FILE && \

      # Atualiza o valor do password do Elastic com o output do Terraform
      sed -i 's|^elasticsearch_password=.*|elasticsearch_password="${ec_deployment.crypto_dash.elasticsearch_password}"|' $INVENTORY_FILE
    EOT
  }
  depends_on = [ec_deployment.crypto_dash]
}