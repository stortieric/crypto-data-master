import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import org.apache.spark.sql.streaming.Trigger
import software.amazon.msk.auth.iam.IAMClientCallbackHandler

val spark = { 
  SparkSession.builder()
  .appName("Kafka Spark Consumer")
  .getOrCreate()
}

val map_schema = {
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

val struct_schema = {
  new StructType()
    .add("bars", MapType(StringType, crypto_schema))
}

val kafka_bootstrap_server = "b-1.cryptokafka.3jjhoc.c22.kafka.us-east-1.amazonaws.com:9098"
val kafka_topic = "coinbase-currencies"

val kafka_options = Map(
  "kafka.bootstrap.servers" -> kafka_bootstrap_server,
  "kafka.security.protocol" -> "SASL_SSL",
  "kafka.sasl.mechanism" -> "AWS_MSK_IAM",
  "kafka.sasl.jaas.config" -> "software.amazon.msk.auth.iam.IAMLoginModule required;",
  "kafka.sasl.client.callback.handler.class" -> "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
)

val kafka_stream_crypto = {
  spark
  .readStream
  .format("kafka")
  .options(kafka_options)
  .option("subscribe", kafka_topic)
  .load()
}

val crypto_df  = {
  kafka_stream_crypto
    .select(expr("CAST(value AS STRING)").alias("json_str"))
    .select(from_json(col("json_str"), struct_schema).as("data"))
    .selectExpr("explode(data.bars) as (tp_moeda, vl_detalhes)")
    .select(
      col("tp_moeda"),
      col("vl_detalhes.c").as("vl_cotacao"),
      col("vl_detalhes.t").as("dt_atualizacao")
    )
}

val query = {
  crypto_df
  .writeStream
  .outputMode("append")
  .format("console")
  .trigger(Trigger.ProcessingTime("1 minute"))
  .start()
}