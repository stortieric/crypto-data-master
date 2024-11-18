import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import org.apache.spark.sql.streaming.Trigger
import org.apache.iceberg.catalog.TableIdentifier
import org.apache.iceberg.spark.SparkCatalog
import software.amazon.msk.auth.iam.IAMClientCallbackHandler

object KafkaConsumerTraderS3 {

  def main(args: Array[String]): Unit = {

    if (args.length != 1) {
      println("Usage: KafkaConsumerTraderS3 <kafkaBootstrapServer>")
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

    val kafkaSchema = {
      new StructType()
        .add("transaction_id", LongType)
        .add("quantity", IntegerType)
        .add("asset_type", StringType)
        .add("trade_type", StringType)
        .add("ref_date", StringType)  
        .add("transaction_timestamp", StringType)
        .add("asset_id", StringType)
        .add("document_id", StringType)
    }

    val kafkaBootstrapServer = args(0)
    val kafkaTopic = "coinbase-trades"

    val kafkaOptions = Map(
      "kafka.bootstrap.servers" -> kafkaBootstrapServer,
      "kafka.security.protocol" -> "SASL_SSL",
      "kafka.sasl.mechanism" -> "AWS_MSK_IAM",
      "kafka.sasl.jaas.config" -> "software.amazon.msk.auth.iam.IAMLoginModule required;",
      "kafka.sasl.client.callback.handler.class" -> "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
    )

    val kafkaStreamTrader = {
      spark.readStream
        .format("kafka")
        .options(kafkaOptions)
        .option("subscribe", kafkaTopic)
        .load()
    }

    val traderDf = {
      kafkaStreamTrader
        .select(expr("CAST(value AS STRING)").alias("json_str"))
        .select(from_json(col("json_str"), kafkaSchema).as("data"))
        .select(
          col("data.transaction_id"),
          col("data.document_id"),
          col("data.asset_id"),
          col("data.asset_type"),
          to_timestamp(col("data.transaction_timestamp"), "yyyy-MM-dd HH:mm:ss").as("transaction_timestamp"),
          col("data.trade_type"),
          col("data.quantity"),
          to_date(col("data.ref_date"), "yyyy-MM-dd").as("ref_date")
        )
        .withWatermark("transaction_timestamp", "2 minutes")
    }

    val query = {
      traderDf
      .writeStream
      .outputMode("append")
      .format("iceberg")
      .option("path", "glue_catalog.crypto_db.crypto_trader")
      .option("checkpointLocation", "s3://bronze-iceberg-data/tables/checkpoint/crypto_trader")
      .trigger(Trigger.ProcessingTime("10 seconds"))
      .start()
      .awaitTermination()
    }

  }

}