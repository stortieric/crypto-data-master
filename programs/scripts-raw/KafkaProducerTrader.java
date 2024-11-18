package com.kafka.coins;

import java.util.Properties;
import java.util.Random;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.sql.Date;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.json.JSONObject;

public class KafkaProducerTrader {

	private static final String KAFKA_TOPIC = "coinbase-trades";

	public static void main(String[] args) {

		if (args.length < 1) {
			System.out.println("Por favor, forneça BOOTSTRAP_SERVERS.");
			System.exit(1);
		}

		String BOOTSTRAP_SERVERS = args[0];

		Properties props = new Properties();
		props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
		props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
		props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
		props.put("security.protocol", "SASL_SSL");
		props.put("sasl.mechanism", "AWS_MSK_IAM");
		props.put("sasl.jaas.config", "software.amazon.msk.auth.iam.IAMLoginModule required;");
		props.put("sasl.client.callback.handler.class", "software.amazon.msk.auth.iam.IAMClientCallbackHandler");

		KafkaProducer<String, String> producer = new KafkaProducer<>(props);
		Random random = new Random();
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

		try {

			while (true) {
				
				JSONObject json = new JSONObject();
				long transactionId = random.nextLong();
				String documentId = String.valueOf(random.nextInt(100000));
				String assetId = random.nextBoolean() ? "BTC" : "LTC"; 
				String assetType = "USD";
				LocalDateTime transactionTimestamp = LocalDateTime.now();
				String tradeType = random.nextBoolean() ? "BUY" : "SELL";
				int quantity = random.nextInt(100);
				Date refDate = Date.valueOf(transactionTimestamp.toLocalDate());

				json.put("transaction_id", transactionId);
				json.put("document_id", documentId);
				json.put("asset_id", assetId);
				json.put("asset_type", assetType);
				json.put("transaction_timestamp", transactionTimestamp.format(formatter));
				json.put("trade_type", tradeType);
				json.put("quantity", quantity);
				json.put("ref_date", refDate);

				ProducerRecord<String, String> record = new ProducerRecord<>(KAFKA_TOPIC, json.toString());
				producer.send(record, (metadata, exception) -> {
					if (exception == null) {
						System.out.println("Registro enviado para " + metadata.topic() + " partição "
								+ metadata.partition() + " com offset " + metadata.offset());
					} else {
						exception.printStackTrace();
					}
				});
			
				Thread.sleep(5000);
			
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			producer.close();
		}

	}
	
}