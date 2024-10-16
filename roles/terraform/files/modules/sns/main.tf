resource "aws_sns_topic" "alarme_topico" {
    name = "crypto-lake-alarme"
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}

resource "aws_sns_topic_subscription" "email_alarme_subscription" {
    topic_arn = aws_sns_topic.alarme_topico.arn
    protocol = "email"
    endpoint = "ericstorti@outlook.com" # Substitua pelo seu e-mail
}

output "alarme_topico_arn" {
    value = aws_sns_topic.alarme_topico.arn
}