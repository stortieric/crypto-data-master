variable "dir_raiz_projeto" {
  type = string
}

variable "coin_api_key" {
  type = string
}

data "external" "ip_local" {
  program = ["bash", "${var.dir_raiz_projeto}/programs/obter-ip-local.sh"]
}

output "ip_local_client" {
  value = data.external.ip_local.result["ip"]
}

module "vpc" {
  source = "./modules/vpc"
}

module "s3" {
  source = "./modules/s3"
  dir_raiz_s3 = var.dir_raiz_projeto
}

module "kafka" {
  source = "./modules/kafka"
  vpc_msk = module.vpc.vpc_id
  ip_local_msk = data.external.ip_local.result["ip"]
  dir_raiz_msk = var.dir_raiz_projeto
}

module "iam" {
  source = "./modules/iam"
}

module "ec2" {
  source = "./modules/ec2"
  vpc_ec2 = module.vpc.vpc_id
  rota_publica_ec2 = module.vpc.rota_publica_id
  iam_inst_prof_msk_ec2 = module.iam.msk_instance_profile_name
  ip_local_ec2 = data.external.ip_local.result["ip"]
  sg_kms_id_ec2 = module.kafka.sg_kms_id
  dir_raiz_ec2 = var.dir_raiz_projeto
}

module "emr" {
  source = "./modules/emr"
  vpc_emr = module.vpc.vpc_id
  rota_publica_emr = module.vpc.rota_publica_id
  ins_prof_arn_emr = module.iam.emr_instance_profile_arn
  servico_role_emr = module.iam.emr_servico_role
  ip_local_emr = data.external.ip_local.result["ip"]
  sg_kms_id_emr = module.kafka.sg_kms_id
}

module "sns" {
  source = "./modules/sns"
}

module "glue" {
  source = "./modules/glue"
}

module "macie" {
  source = "./modules/macie"
  bucket_nomes_macie = module.s3.buckets_iceberg_data
}

module "lambda" {
  source = "./modules/lambda"
  engenheiro_servico_role_lambda = module.iam.engenheiro_servico_role
  bucket_programs_lake_lambda = module.s3.bucket_programs_lake
  coin_api_key_lambda = var.coin_api_key
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
  alarme_topico_cw = module.sns.alarme_topico_arn
  bucket_nomes_cw = module.s3.buckets_iceberg_data
  otimiza_tabelas_arn_cw = module.lambda.otimiza_tabelas_lambda_arn
  otimiza_tabelas_name_cw = module.lambda.otimiza_tabelas_lambda_name
  atualiza_icons_arn_cw = module.lambda.atualiza_icons_lambda_arn
  atualiza_icons_name_cw = module.lambda.atualiza_icons_lambda_name
}

module "elastic" {
  source = "./modules/elastic"
}

