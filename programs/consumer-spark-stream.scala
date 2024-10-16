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

val barSchema = {
  new StructType()
    .add("c", DoubleType)
    .add("h", DoubleType)
    .add("l", DoubleType)
    .add("n", IntegerType)
    .add("o", DoubleType)
    .add("t", TimestampType)
    .add("v", DoubleType)
    .add("vw", DoubleType)
}

val topSchema = {
  new StructType()
    .add("bars", MapType(StringType, barSchema))
}

val kafkaBootstrapServers = "b-1.cryptokafka.3jjhoc.c22.kafka.us-east-1.amazonaws.com:9098"
val kafkaTopic = "coinbase-currencies"

val kafkaOptions = Map(
  "kafka.bootstrap.servers" -> kafkaBootstrapServers,
  "kafka.security.protocol" -> "SASL_SSL",
  "kafka.sasl.mechanism" -> "AWS_MSK_IAM",
  "kafka.sasl.jaas.config" -> "software.amazon.msk.auth.iam.IAMLoginModule required;",
  "kafka.sasl.client.callback.handler.class" -> "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
)

val kafkaStreamDF = {
  spark
  .readStream
  .format("kafka")
  .options(kafkaOptions)
  .option("subscribe", kafkaTopic)
  .load()
}

val parsedDF = {
  kafkaStreamDF
    .select(expr("CAST(value AS STRING)").alias("json_str"))
    .select(from_json(col("json_str"), topSchema).as("data"))
    .selectExpr("explode(data.bars) as (currency, barDetails)")
    .select(
      col("currency"),
      col("barDetails.c").as("c"),
      col("barDetails.t").as("t")
    )
}

val query = {
  parsedDF.writeStream
  .outputMode("append")
  .format("console")
  .trigger(Trigger.ProcessingTime("1 minute"))
  .start()
}