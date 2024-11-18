variable "vpc_emr" {
  type = string
}

variable "rota_publica_emr" {
  type = string
}

variable "ins_prof_arn_emr" {
  type = string
}

variable "servico_role_emr" {
  type = string
}

variable "ip_local_emr" {
  type = string
}

variable "sg_kms_id_emr" {
  type = string
}

variable "dir_raiz_emr" {
  type = string
}

resource "aws_subnet" "subnet_emr" {
  vpc_id = var.vpc_emr
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "public_assoc_emr" {
  subnet_id = aws_subnet.subnet_emr.id
  route_table_id = var.rota_publica_emr
}

resource "aws_security_group" "emr_seg_grp" {
  name = "emr-lake-seg-grp"
  vpc_id = var.vpc_emr
  ingress {
    from_port = 22           
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ip_local_emr}/32"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "tls_key_emr_s3_crypto" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "key_pair_emr_s3_crypto" {
  key_name = "emr-key-s3-crypto"
  public_key = tls_private_key.tls_key_emr_s3_crypto.public_key_openssh
}

resource "tls_private_key" "tls_key_emr_s3_trader" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "key_pair_emr_s3_trader" {
  key_name = "emr-key-s3-trader"
  public_key = tls_private_key.tls_key_emr_s3_trader.public_key_openssh
}

resource "tls_private_key" "tls_key_emr_els" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "key_pair_emr_els" {
  key_name = "emr-key-els"
  public_key = tls_private_key.tls_key_emr_els.public_key_openssh
}

resource "aws_emr_cluster" "emr_cluster_s3_crypto" {
  name = "crypto-lake-emr-crypto"
  release_label = "emr-7.3.0"
  applications = ["Spark", "Hive", "JupyterEnterpriseGateway", "AmazonCloudWatchAgent", "Livy", "Hadoop"]
  ec2_attributes {
    subnet_id = aws_subnet.subnet_emr.id
    emr_managed_master_security_group = aws_security_group.emr_seg_grp.id
    emr_managed_slave_security_group  = aws_security_group.emr_seg_grp.id
    instance_profile = var.ins_prof_arn_emr
    key_name = aws_key_pair.key_pair_emr_s3_crypto.key_name
  }
  master_instance_group {
    instance_type = "m5.xlarge"
  }
  core_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 2
    ebs_config {
      size = "100"
      type = "gp2"
      volumes_per_instance = 1
    }
  }
  configurations_json = <<EOF
  [
    {
      "Classification": "spark-hive-site",
      "Properties": {
        "hive.metastore.client.factory.class": "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
      }
    },
    {
      "Classification": "iceberg-defaults",
      "Properties": {
        "iceberg.enabled": "true"
      }
    }
  ]
EOF
  service_role = var.servico_role_emr
  log_uri = "s3://emr-logs-lake/"
  tags = {
    Name = "crypto-lake"
    Environment = "prd"
  }
}

resource "aws_emr_cluster" "emr_cluster_s3_trader" {
  name = "crypto-lake-emr-trader"
  release_label = "emr-7.3.0"
  applications = ["Spark", "Hive", "JupyterEnterpriseGateway", "AmazonCloudWatchAgent", "Livy", "Hadoop"]
  ec2_attributes {
    subnet_id = aws_subnet.subnet_emr.id
    emr_managed_master_security_group = aws_security_group.emr_seg_grp.id
    emr_managed_slave_security_group  = aws_security_group.emr_seg_grp.id
    instance_profile = var.ins_prof_arn_emr
    key_name = aws_key_pair.key_pair_emr_s3_trader.key_name
  }
  master_instance_group {
    instance_type = "m5.xlarge"
  }
  core_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 2
    ebs_config {
      size = "100"
      type = "gp2"
      volumes_per_instance = 1
    }
  }
  configurations_json = <<EOF
  [
    {
      "Classification": "spark-hive-site",
      "Properties": {
        "hive.metastore.client.factory.class": "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
      }
    },
    {
      "Classification": "iceberg-defaults",
      "Properties": {
        "iceberg.enabled": "true"
      }
    }
  ]
EOF
  service_role = var.servico_role_emr
  log_uri = "s3://emr-logs-lake/"
  tags = {
    Name = "crypto-lake"
    Environment = "prd"
  }
}

resource "aws_emr_cluster" "emr_cluster_els" {
  name = "crypto-lake-emr-els"
  release_label = "emr-6.15.0"
  applications = ["Spark", "Hive", "Livy", "Hadoop"]
  ec2_attributes {
    subnet_id = aws_subnet.subnet_emr.id
    emr_managed_master_security_group = aws_security_group.emr_seg_grp.id
    emr_managed_slave_security_group  = aws_security_group.emr_seg_grp.id
    instance_profile = var.ins_prof_arn_emr
    key_name = aws_key_pair.key_pair_emr_els.key_name
  }
  master_instance_group {
    instance_type = "m5.xlarge"
  }
  core_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 2
    ebs_config {
      size = "100"
      type = "gp2"
      volumes_per_instance = 1
    }
  }
  configurations_json = <<EOF
  [
    {
      "Classification": "spark-hive-site",
      "Properties": {
        "hive.metastore.client.factory.class": "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
      }
    },
    {
      "Classification": "iceberg-defaults",
      "Properties": {
        "iceberg.enabled": "true"
      }
    }
  ]
EOF
  service_role = var.servico_role_emr
  log_uri = "s3://emr-logs-lake/"
  tags = {
    Name = "crypto-lake"
    Environment = "prd"
  }
}

resource "aws_security_group_rule" "permite_emr_s3_els_para_msk" {
  type = "ingress"
  from_port = 0           
  to_port = 65535            
  protocol = "tcp"        
  security_group_id = var.sg_kms_id_emr   
  source_security_group_id = aws_security_group.emr_seg_grp.id
  depends_on = [
    aws_security_group.emr_seg_grp,  
    var.sg_kms_id_emr 
  ]
}

output "private_key_emr_s3_crypto" {
  value = tls_private_key.tls_key_emr_s3_crypto.private_key_pem
  sensitive = true
}

output "private_key_emr_s3_trader" {
  value = tls_private_key.tls_key_emr_s3_trader.private_key_pem
  sensitive = true
}

output "private_key_emr_els" {
  value = tls_private_key.tls_key_emr_els.private_key_pem
  sensitive = true
}

resource "null_resource" "armazena_private_key_emr_s3_crypto" {
  provisioner "local-exec" {
    command = "echo '${tls_private_key.tls_key_emr_s3_crypto.private_key_pem}' > ~/.ssh/emr-key-s3-crypto.pem && chmod 600 ~/.ssh/emr-key-s3-crypto.pem"
  }
  depends_on = [aws_key_pair.key_pair_emr_s3_crypto]
}

resource "null_resource" "armazena_private_key_emr_s3_trader" {
  provisioner "local-exec" {
    command = "echo '${tls_private_key.tls_key_emr_s3_trader.private_key_pem}' > ~/.ssh/emr-key-s3-trader.pem && chmod 600 ~/.ssh/emr-key-s3-trader.pem"
  }
  depends_on = [aws_key_pair.key_pair_emr_s3_trader]
}

resource "null_resource" "armazena_private_key_emr_els" {
  provisioner "local-exec" {
    command = "echo '${tls_private_key.tls_key_emr_els.private_key_pem}' > ~/.ssh/emr-key-els.pem && chmod 600 ~/.ssh/emr-key-els.pem"
  }
  depends_on = [aws_key_pair.key_pair_emr_els]
}

output "emr_master_publico_ip_s3_crypto" {
  value = aws_emr_cluster.emr_cluster_s3_crypto.master_public_dns
}

output "emr_master_publico_ip_s3_trader" {
  value = aws_emr_cluster.emr_cluster_s3_trader.master_public_dns
}

output "emr_master_publico_ip_els" {
  value = aws_emr_cluster.emr_cluster_els.master_public_dns
}

resource "null_resource" "atualiza_ip_emr_s3_crypto" {
  provisioner "local-exec" {
    command = <<EOT
      INVENTORY_FILE="${var.dir_raiz_emr}/inventory.ini"

      # Atualiza o ip do emr s3 com o output do Terraform
      sed -i '24s|.*|${aws_emr_cluster.emr_cluster_s3_crypto.master_public_dns}|' $INVENTORY_FILE
    EOT
  }
  depends_on = [aws_emr_cluster.emr_cluster_s3_crypto]
}

resource "null_resource" "atualiza_ip_emr_s3_trader" {
  provisioner "local-exec" {
    command = <<EOT
      INVENTORY_FILE="${var.dir_raiz_emr}/inventory.ini"

      # Atualiza o ip do emr s3 com o output do Terraform
      sed -i '43s|.*|${aws_emr_cluster.emr_cluster_s3_trader.master_public_dns}|' $INVENTORY_FILE
    EOT
  }
  depends_on = [aws_emr_cluster.emr_cluster_s3_trader]
}

resource "null_resource" "atualiza_ip_emr_els" {
  provisioner "local-exec" {
    command = <<EOT
      INVENTORY_FILE="${var.dir_raiz_emr}/inventory.ini"

      # Atualiza o ip do emr els com o output do Terraform
      sed -i '32s|.*|${aws_emr_cluster.emr_cluster_els.master_public_dns}|' $INVENTORY_FILE
    EOT
  }
  depends_on = [aws_emr_cluster.emr_cluster_els]
}
