variable "dir_raiz_s3" {
  type = string
}

resource "aws_s3_bucket" "bronze_lake" {
    bucket = "bronze-iceberg-data"
    force_destroy = true
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}

resource "aws_s3_bucket_versioning" "versionamento_bronze" {
    bucket = aws_s3_bucket.bronze_lake.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket" "silver_lake" {
    bucket = "silver-iceberg-data"
    force_destroy = true
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}

resource "aws_s3_bucket_versioning" "versionamento_silver" {
    bucket = aws_s3_bucket.silver_lake.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket" "gold_lake" {
    bucket = "gold-iceberg-data"
    force_destroy = true
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}

resource "aws_s3_bucket_versioning" "versionamento_gold" {
    bucket = aws_s3_bucket.gold_lake.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket" "emr_logs" {
    bucket = "emr-logs-lake"
    force_destroy = true
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}

resource "aws_s3_bucket" "programs_lake" {
    bucket = "programs-lake-prd"
    force_destroy = true
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}

resource "aws_s3_bucket" "jars_lake" {
    bucket = "jars-lake-prd"
    force_destroy = true
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}

resource "aws_s3_object" "lambda_cria_tabelas" {
  bucket = aws_s3_bucket.programs_lake.bucket
  key = "create-tables-athena.zip"
  source = "${var.dir_raiz_s3}/programs/create-tables-athena.zip"
}

resource "aws_s3_object" "lambda_otimiza_tabelas" {
  bucket = aws_s3_bucket.programs_lake.bucket
  key = "optimize-tables-athena.zip"
  source = "${var.dir_raiz_s3}/programs/optimize-tables-athena.zip"
}

resource "aws_s3_object" "lambda_atualiza_icons" {
  bucket = aws_s3_bucket.programs_lake.bucket
  key = "update-assets-icons.zip"
  source = "${var.dir_raiz_s3}/programs/update-assets-icons.zip"
}

output "buckets_iceberg_data" {
    value = [
        aws_s3_bucket.bronze_lake.bucket,
        aws_s3_bucket.silver_lake.bucket,
        aws_s3_bucket.gold_lake.bucket
    ]
}

output "bucket_emr_logs" {
    value = aws_s3_bucket.emr_logs.bucket
}

output "bucket_programs_lake" {
    value = aws_s3_bucket.programs_lake.bucket
}