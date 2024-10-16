variable "alarme_topico_cw" {
  type = string
}

variable "bucket_nomes_cw" {
  type = list(string)
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
