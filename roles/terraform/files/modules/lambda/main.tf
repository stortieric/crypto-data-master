variable "engenheiro_servico_role_lambda" {
  type = string
}

variable "bucket_programs_lake_lambda" {
  type = string
}

variable "coin_api_key_lambda" {
  type = string
}

resource "aws_lambda_function" "executa_queries" {
  function_name = "executa-criacao-tabelas"
  role = var.engenheiro_servico_role_lambda
  handler = "create-tables-athena.create_tables"
  runtime = "python3.9"

  s3_bucket = var.bucket_programs_lake_lambda
  s3_key = "create-tables-athena.zip"

  timeout = 60
}

resource "aws_lambda_function" "otimiza_tabelas_lambda" {
  function_name = "executa-otimizacao-tabelas"
  role = var.engenheiro_servico_role_lambda
  handler = "optimize-tables-athena.optimize_tables"
  runtime = "python3.9"

  s3_bucket = var.bucket_programs_lake_lambda
  s3_key = "optimize-tables-athena.zip"

  timeout = 900
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


