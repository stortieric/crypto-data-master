resource "aws_glue_catalog_database" "iceberg_db" {
    name = "crypto_db"
    tags = {
        Name = "crypto-lake"
        Environment = "prd"
    }
}
