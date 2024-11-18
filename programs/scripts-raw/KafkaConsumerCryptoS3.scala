import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import org.apache.spark.sql.streaming.Trigger
import org.apache.iceberg.catalog.TableIdentifier
import org.apache.iceberg.spark.SparkCatalog
import software.amazon.msk.auth.iam.IAMClientCallbackHandler

object KafkaConsumerCryptoS3 {

  def main(args: Array[String]): Unit = {

    if (args.length != 1) {
      println("Usage: KafkaConsumerCryptoS3 <kafkaBootstrapServer>")
      System.exit(1)
    }

    val spark = { 
      SparkSession.builder()
        .appName("Kafka Consumer Crypto S3")
        .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.glue_catalog.warehouse", "s3://bronze-iceberg-data/tables")
        .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
        .config("spark.sql.catalog.glue_catalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
        .getOrCreate()
    }

    val mapSchema = {
      new StructType()
        .add("c", DoubleType)
        .add("h", DoubleType)
        .add("l", DoubleType)
        .add("n", DoubleType)
        .add("o", DoubleType)
        .add("t", TimestampType)
        .add("v", DoubleType)
        .add("vw", DoubleType)
    }

    val structSchema = {
      new StructType()
        .add("bars", MapType(StringType, mapSchema))
    }

    val kafkaBootstrapServer = args(0)
    val kafkaTopic = "coinbase-currencies"

    val kafkaOptions = Map(
      "kafka.bootstrap.servers" -> kafkaBootstrapServer,
      "kafka.security.protocol" -> "SASL_SSL",
      "kafka.sasl.mechanism" -> "AWS_MSK_IAM",
      "kafka.sasl.jaas.config" -> "software.amazon.msk.auth.iam.IAMLoginModule required;",
      "kafka.sasl.client.callback.handler.class" -> "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
    )

    val kafkaStreamCrypto = {
      spark.readStream
      .format("kafka")
      .options(kafkaOptions)
      .option("subscribe", kafkaTopic)
      .load()
    }

    val cryptoDf  = {
      kafkaStreamCrypto
      .select(expr("CAST(value AS STRING)").alias("json_str"))
      .select(from_json(col("json_str"), structSchema).as("data"))
      .selectExpr("explode(data.bars) as (tp_moeda, vl_detalhes)")
      .select(
        split(col("tp_moeda"), "/").getItem(0).as("asset_id"),
        split(col("tp_moeda"), "/").getItem(1).as("asset_type"), 
        col("vl_detalhes.c").as("price_crypto"),
        col("vl_detalhes.t").as("dt_atualizacao")
      )
      .withColumn("ref_date", current_date())
      .withWatermark("dt_atualizacao", "2 minutes")
      .groupBy(
        col("asset_id"),
        col("asset_type"),
        col("ref_date"), 
        window(col("dt_atualizacao"), "1 minute")
      )
      .agg(
        max("price_crypto").as("price_crypto")
      )
      .select(
        col("asset_id"),
        col("asset_type"),
        col("window.start").as("start_window"),
        col("window.end").as("end_window"),
        col("price_crypto"),
        col("ref_date")
      )
    }

    val query = {
      cryptoDf
      .writeStream
      .outputMode("append")
      .format("iceberg")
      .option("path", "glue_catalog.crypto_db.crypto_quote")
      .option("checkpointLocation", "s3://bronze-iceberg-data/tables/checkpoint/crypto_quote")
      .trigger(Trigger.ProcessingTime("1 minute"))
      .start()
      .awaitTermination()
    }

  }
  
}