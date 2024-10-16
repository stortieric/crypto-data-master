variable "vpc_ec2" {
  type = string
}

variable "iam_inst_prof_msk_ec2" {
  type = string
}

variable "ip_local_ec2" {
  type = string
}

variable "sg_kms_id_ec2" {
  type = string
}

resource "aws_subnet" "subnet_ec2_msk" {
  vpc_id = var.vpc_ec2
  cidr_block = "10.4.0.0/16"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw_ec2" {
  vpc_id = var.vpc_ec2
}

resource "aws_route_table" "rota_publica_ec2" {
  vpc_id = var.vpc_ec2
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_ec2.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.subnet_ec2_msk.id
  route_table_id = aws_route_table.rota_publica_ec2.id
}

resource "tls_private_key" "tls_key_ec2" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "key_pair_ec2" {
  key_name = "kms-client-key"
  public_key = tls_private_key.tls_key_ec2.public_key_openssh
}

resource "aws_security_group" "sg_ec2_kms" {
  name = "sg-ec2-kms-lake"
  vpc_id = var.vpc_ec2
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ip_local_ec2}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_msk_client" {
  ami = "ami-00f251754ac5da7f0"  
  instance_type = "t3.medium"
  key_name = aws_key_pair.key_pair_ec2.key_name
  subnet_id = aws_subnet.subnet_ec2_msk.id
  iam_instance_profile = var.iam_inst_prof_msk_ec2
  vpc_security_group_ids = [aws_security_group.sg_ec2_kms.id]
  associate_public_ip_address = true
  tags = {
    Name = "crypto-lake"
    Environment = "prd"
  }
  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y java-11-amazon-corretto
EOF
}

resource "aws_security_group_rule" "permite_ec2_para_msk" {
  type = "ingress"
  from_port = 0           
  to_port = 65535            
  protocol = "tcp"        
  security_group_id = var.sg_kms_id_ec2   
  source_security_group_id = aws_security_group.sg_ec2_kms.id
  depends_on = [
      aws_security_group.sg_ec2_kms,  
      var.sg_kms_id_ec2 
  ]
}

output "private_key_ec2_msk" {
  value = tls_private_key.tls_key_ec2.private_key_pem
  sensitive = true
}

resource "null_resource" "armazena_private_key_ec2" {
  provisioner "local-exec" {
    command = "echo '${tls_private_key.tls_key_ec2.private_key_pem}' > ~/.ssh/kms-client-key.pem && chmod 600 ~/.ssh/kms-client-key.pem"
  }
  depends_on = [aws_key_pair.key_pair_ec2]
}

output "instance_public_ip" {
  value = aws_instance.ec2_msk_client.public_ip
}

resource "null_resource" "atualiza_ip_ec2_msk" {
  provisioner "local-exec" {
    command = <<EOT
      INVENTORY_FILE=../../../../../inventory.ini

      # Atualiza o ip do ec2 client com o output do Terraform
      sed -i '5s|.*|${instance_public_ip}|' $INVENTORY_FILE
    EOT
  }
  depends_on = [aws_instance.ec2_msk_client] 
}