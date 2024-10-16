data "external" "ip_local" {
  program = ["bash", "../../programs/obter-ip-local.sh"]
}

output "ip_local_client" {
  value = data.external.ip_local.result["ip"]
}

module "vpc" {
  source = "./modules/vpc"
}

module "s3" {
  source = "./modules/s3"
}

module "kafka" {
  source = "./modules/kafka"
  vpc_msk = module.vpc.vpc_id
  ip_local_msk = ip_local_client
}

module "iam" {
  source = "./modules/iam"
}

module "ec2" {
  source = "./modules/ec2"
  vpc_ec2 = module.vpc.vpc_id
  iam_inst_prof_msk_ec2 = module.iam.msk_instance_profile_name
  ip_local_ec2 = ip_local_client
  sg_kms_id_ec2 = module.kafka.sg_kms_id
}

module "emr" {
  source = "./modules/emr"
  vpc_emr = module.vpc.vpc_id
  ins_prof_arn_emr = module.iam.emr_instance_profile_arn
  servico_role_emr = module.iam.emr_servico_role
  ip_local_emr = ip_local_client
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

module "cloudwatch" {
  source = "./modules/cloudwatch"
  alarme_topico_cw = module.sns.alarme_topico_arn
  bucket_nomes_cw = module.s3.buckets_iceberg_data
}
