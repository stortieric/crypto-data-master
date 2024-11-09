variable "vpc_msk" {
  type = string
}

variable "ip_local_msk" {
  type = string
}

variable "dir_raiz_msk" {
  type = string
}

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_subnet" "subnet_kms_az1" {
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block = "10.0.1.0/24"
  vpc_id = var.vpc_msk
}

resource "aws_subnet" "subnet_kms_az2" {
  availability_zone = data.aws_availability_zones.azs.names[1]
  cidr_block = "10.0.2.0/24"
  vpc_id = var.vpc_msk
}

resource "aws_subnet" "subnet_kms_az3" {
  availability_zone = data.aws_availability_zones.azs.names[2]
  cidr_block = "10.0.3.0/24"
  vpc_id = var.vpc_msk
}

resource "aws_security_group" "kms_seg_grp" {
  name = "kms-lake-seg-grp"
  vpc_id = var.vpc_msk
  ingress {
    from_port = 22           
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ip_local_msk}/32"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_kms_key" "kms_criptografia" {
  description = "criptografia"
}

resource "aws_msk_cluster" "kafka" {
  cluster_name = "crypto-lake-kms"
  kafka_version = "3.5.1" 
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type = "kafka.t3.small"
    client_subnets = [
      aws_subnet.subnet_kms_az1.id,
      aws_subnet.subnet_kms_az2.id,
      aws_subnet.subnet_kms_az3.id,
    ]
    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }
    security_groups = [aws_security_group.kms_seg_grp.id]
  }
  client_authentication {
    unauthenticated = true
    sasl {
      iam = true
    }
  }
  enhanced_monitoring = "DEFAULT"
  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kms_criptografia.arn
  }
  tags = {
    Name = "crypto-lake"
    Environment = "prd"
  }
}

resource "aws_msk_configuration" "config_kms" {
  name = "config-kms"
  kafka_versions = ["3.5.1"]
  server_properties = <<PROPERTIES
auto.create.topics.enable = true
delete.topic.enable = true
PROPERTIES
}

output "sg_kms_id" {
  value = aws_security_group.kms_seg_grp.id
}

output "bootstrap_brokers_iam" {
  value = aws_msk_cluster.kafka.bootstrap_brokers_sasl_iam
}

resource "null_resource" "atualiza_bootstrap_server_msk" {
  provisioner "local-exec" {
    command = <<EOT
      INVENTORY_FILE="${var.dir_raiz_msk}/inventory.ini"

      # Atualiza o valor do kafka_bootstrap_server com o output Terraform
      sed -i 's|^kafka_bootstrap_server=.*|kafka_bootstrap_server="${aws_msk_cluster.kafka.bootstrap_brokers_sasl_iam}"|' $INVENTORY_FILE
    EOT
  }
  depends_on = [aws_msk_cluster.kafka]
}