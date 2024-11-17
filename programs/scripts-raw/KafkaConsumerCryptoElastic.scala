import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import org.apache.spark.sql.streaming.Trigger
import software.amazon.msk.auth.iam.IAMClientCallbackHandler

object KafkaConsumerCryptoElastic {

  def main(args: Array[String]): Unit = {

    if (args.length != 4) {
      println("Usage: KafkaConsumerCryptoElastic <kafkaBootstrapServer> <es.nodes> <es.port> <es.net.http.auth.pass>")
      System.exit(1)
    }

    val spark = { 
      SparkSession.builder()
        .appName("Kafka Consumer Crypto Elastic")
        .config("es.index.auto.create", "true")
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

    val esNodes = args(1)
    val esPort = args(2)
    val esAuthPass = args(3)

    val query = {
      cryptoDf
        .writeStream
        .outputMode("append")
        .format("org.elasticsearch.spark.sql")
        .option("es.nodes.wan.only", "true")
        .option("es.nodes", esNodes)
        .option("es.port", esPort)
        .option("es.net.ssl", "true")
        .option("es.resource", "crypto_quote")
        .option("es.net.http.auth.user", "elastic")
        .option("es.net.http.auth.pass", esAuthPass)
        .option("checkpointLocation", "s3://bronze-iceberg-data/tables/checkpoint/crypto_quote_elastic")
        .trigger(Trigger.ProcessingTime("1 minute"))
        .start()
        .awaitTermination()
    }
  }
}
