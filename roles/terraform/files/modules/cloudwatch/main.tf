variable "alarme_topico_cw" {
  type = string
}

variable "bucket_nomes_cw" {
  type = list(string)
}

variable "otimiza_tabelas_arn_cw" {
  type = string
}

variable "otimiza_tabelas_name_cw" {
  type = string
}

variable "atualiza_icons_arn_cw" {
  type = string
}

variable "atualiza_icons_name_cw" {
  type = string
}

resource "aws_cloudwatch_metric_alarm" "s3_tamanho_bucket_alarme" {
    for_each = toset(var.bucket_nomes_cw)
    alarm_name = "${each.key}-tamanho-alarme"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = "1"
    metric_name = "tamanho-max-bucket"
    namespace = "AWS/S3"
    period = "86400"
    statistic = "Average"
    threshold = "1000000000" 
    dimensions = {
        BucketName = each.key
        StorageType = "StandardStorage"
    }
    alarm_description = "Dispara o alarme quando o bucket S3 excede 1GB"
    alarm_actions = [var.alarme_topico_cw]
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}

resource "aws_cloudwatch_metric_alarm" "macie_anomalias_alarme" {
    alarm_name = "macie-anomalias-alarme"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "1"
    metric_name = "contagem-anomalias"
    namespace = "AWS/Macie"
    period = "86400" 
    statistic = "Sum"
    threshold = "10" 
    alarm_description = "Alarme que detecta mais de 10 dados sensiveis no Macie"
    alarm_actions = [var.alarme_topico_cw]
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}

resource "aws_cloudwatch_event_rule" "otimiza_tabelas_agenda" {
  name = "otimiza-tabelas-agenda"
  schedule_expression = "cron(0 2 ? * 7 *)"
}

resource "aws_cloudwatch_event_target" "otimiza_tabela_evento" {
  rule = aws_cloudwatch_event_rule.otimiza_tabelas_agenda.name
  target_id = "otimiza-tabelas-destino"
  arn = var.otimiza_tabelas_arn_cw
}

resource "aws_lambda_permission" "permissao_oti_tab_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = var.otimiza_tabelas_name_cw
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.otimiza_tabelas_agenda.arn
}

resource "aws_cloudwatch_event_rule" "atualiza_icons_agenda" {
  name = "atualiza-icons-agenda"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "atualiza_icons_evento" {
  rule = aws_cloudwatch_event_rule.atualiza_icons_agenda.name
  target_id = "atualiza-icons-destino"
  arn = var.atualiza_icons_arn_cw
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = var.atualiza_icons_name_cw
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.atualiza_icons_agenda.arn
}