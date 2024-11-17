#!/bin/bash
/lib/spark/bin/spark-submit \
  --deploy-mode cluster \
  --packages org.elasticsearch:elasticsearch-spark-30_2.12:8.15.3,org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,software.amazon.msk:aws-msk-iam-auth:2.2.0 \
  --class KafkaConsumerCryptoElastic \
  "$2" \
  "$1" "$3" "$4" "$5" > "$6" 2>&1 &
echo $! > "${6%.log}.pid"
