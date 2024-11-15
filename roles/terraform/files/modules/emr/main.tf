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

resource "tls_private_key" "tls_key_emr" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "key_pair_emr" {
  key_name = "emr-key"
  public_key = tls_private_key.tls_key_emr.public_key_openssh
}

resource "aws_emr_cluster" "emr_cluster" {
  name = "crypto-lake-emr"
  release_label = "emr-7.3.0"
  applications = ["Spark", "Hive", "JupyterEnterpriseGateway", "AmazonCloudWatchAgent", "Livy", "Hadoop"]
  ec2_attributes {
    subnet_id = aws_subnet.subnet_emr.id
    emr_managed_master_security_group = aws_security_group.emr_seg_grp.id
    emr_managed_slave_security_group  = aws_security_group.emr_seg_grp.id
    instance_profile = var.ins_prof_arn_emr
    key_name = aws_key_pair.key_pair_emr.key_name
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

resource "aws_security_group_rule" "permite_emr_para_msk" {
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

output "private_key_emr" {
  value = tls_private_key.tls_key_emr.private_key_pem
  sensitive = true
}

resource "null_resource" "armazena_private_key_emr" {
  provisioner "local-exec" {
    command = "echo '${tls_private_key.tls_key_emr.private_key_pem}' > ~/.ssh/emr-key.pem && chmod 600 ~/.ssh/emr-key.pem"
  }
  depends_on = [aws_key_pair.key_pair_emr]
}
