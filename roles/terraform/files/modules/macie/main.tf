variable "bucket_nomes_macie" {
    type = list(string)
}

variable "habilita_macie" {
    type = bool
    default = false
}

resource "aws_macie2_account" "busca_dados_sensiveis" {
    count = var.habilita_macie ? 1 : 0
    finding_publishing_frequency = "FIFTEEN_MINUTES"
}

resource "aws_macie2_classification_job" "find_sensitive_data" {
    count = var.habilita_macie ? 1 : 0
    job_type = "ONE_TIME"
    name = "procura-dados-sensiveis"
    s3_job_definition {
        bucket_definitions {
            account_id = aws_macie2_account.busca_dados_sensiveis[count.index].id
            buckets = var.bucket_nomes_macie
        }
    }
    depends_on = [aws_macie2_account.busca_dados_sensiveis]
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}