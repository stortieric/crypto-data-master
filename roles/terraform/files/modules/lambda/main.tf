variable "engenheiro_servico_role_lambda" {
  type = string
}

variable "bucket_programs_lake_lambda" {
  type = string
}

variable "coin_api_key_lambda" {
  type = string
}

variable "dir_raiz_lambda" {
  type = string
}

resource "aws_s3_object" "lambda_cria_tabelas" {
  bucket = var.bucket_programs_lake_lambda
  key = "create-tables-athena.zip"
  source = "${var.dir_raiz_lambda}/programs/create-tables-athena.zip"
}

output "lambda_cria_tabelas_key" {
  value = aws_s3_object.lambda_cria_tabelas.key
}

resource "aws_s3_object" "lambda_otimiza_tabelas" {
  bucket = var.bucket_programs_lake_lambda
  key = "optimize-tables-athena.zip"
  source = "${var.dir_raiz_lambda}/programs/optimize-tables-athena.zip"
}

output "lambda_otimiza_tabelas_key" {
  value = aws_s3_object.lambda_otimiza_tabelas.key
}

resource "aws_s3_object" "lambda_atualiza_icons" {
  bucket = var.bucket_programs_lake_lambda
  key = "update-assets-icons.zip"
  source = "${var.dir_raiz_lambda}/programs/update-assets-icons.zip"
}

output "lambda_atualiza_icons_key" {
  value = aws_s3_object.lambda_atualiza_icons.key
}

resource "aws_lambda_function" "executa_criacao_tabelas" {
  function_name = "executa-criacao-tabelas"
  role = var.engenheiro_servico_role_lambda
  handler = "create-tables-athena.create_tables"
  runtime = "python3.9"
  s3_bucket = var.bucket_programs_lake_lambda
  s3_key = "create-tables-athena.zip"
  timeout = 60
  depends_on = [aws_s3_object.lambda_cria_tabelas]
  tags = {
    Name = "crypto-lake"
    Environment = "prd"
  }
}

resource "aws_lambda_function" "otimiza_tabelas_lambda" {
  function_name = "executa-otimizacao-tabelas"
  role = var.engenheiro_servico_role_lambda
  handler = "optimize-tables-athena.optimize_tables"
  runtime = "python3.9"
  s3_bucket = var.bucket_programs_lake_lambda
  s3_key = "optimize-tables-athena.zip"
  timeout = 900
  depends_on = [aws_s3_object.lambda_otimiza_tabelas]
  tags = {
    Name = "crypto-lake"
    Environment = "prd"
  }
}

resource "aws_lambda_function" "atualiza_icons_lambda" {
  function_name = "atualiza-assets-icons"
  role = var.engenheiro_servico_role_lambda
  handler = "update-assets-icons.insert_icons" 
  runtime = "python3.9"
  s3_bucket = var.bucket_programs_lake_lambda
  s3_key = "update-assets-icons.zip"
  environment {
    variables = {
      COIN_API_KEY = var.coin_api_key_lambda
    }
  }
  timeout = 900
  tags = {
    Name = "crypto-lake"
    Environment = "prd"
  }
  depends_on = [aws_s3_object.lambda_atualiza_icons]
}

output "otimiza_tabelas_lambda_arn" {
    value = aws_lambda_function.otimiza_tabelas_lambda.arn
}

output "otimiza_tabelas_lambda_name" {
    value = aws_lambda_function.otimiza_tabelas_lambda.function_name
}

output "atualiza_icons_lambda_arn" {
    value = aws_lambda_function.atualiza_icons_lambda.arn
}

output "atualiza_icons_lambda_name" {
    value = aws_lambda_function.atualiza_icons_lambda.function_name
}