#!/bin/bash
/lib/spark/bin/spark-submit \
  --deploy-mode cluster \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1,software.amazon.msk:aws-msk-iam-auth:2.2.0,org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.7.0,org.apache.iceberg:iceberg-aws-bundle:1.7.0 \
  --class "$3" \
  "$2" \
  "$1" > "$4" 2>&1 &
echo $! > "${4%.log}.pid"