package com.kafka.coins;

import java.util.Properties;

import org.apache.http.client.methods.CloseableHttpResponse; 
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;

public class KafkaProducerCurrencies {

	private static final String KAFKA_TOPIC = "coinbase-currencies";
	
	public static void main(String[] args) {
		
        if (args.length < 3) {
            System.out.println("Por favor, forneça ALPACA_API_KEY, ALPACA_SECRET_KEY e BOOTSTRAP_SERVERS.");
            System.exit(1);
        }

        String ALPACA_API_KEY = args[0];
        String ALPACA_SECRET_KEY = args[1];
        String BOOTSTRAP_SERVERS = args[2];

		Properties props = new Properties();
		props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
		props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
		props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
		props.put("security.protocol", "SASL_SSL");
        props.put("sasl.mechanism", "AWS_MSK_IAM");
        props.put("sasl.jaas.config", "software.amazon.msk.auth.iam.IAMLoginModule required;");
        props.put("sasl.client.callback.handler.class", "software.amazon.msk.auth.iam.IAMClientCallbackHandler");

       KafkaProducer<String, String> producer = new KafkaProducer<>(props);

		try (CloseableHttpClient httpClient = HttpClients.createDefault()) {
			
			while (true) {
				
				HttpGet request = new HttpGet("https://data.alpaca.markets/v1beta3/crypto/us/latest/bars?symbols=BTC%2FUSD%2CLTC%2FUSD");
				request.setHeader("APCA-API-KEY-ID", ALPACA_API_KEY);
				request.setHeader("APCA-API-SECRET-KEY", ALPACA_SECRET_KEY);

				try (CloseableHttpResponse response = httpClient.execute(request)) {
					
					String responseData = EntityUtils.toString(response.getEntity());

					ProducerRecord<String, String> record = new ProducerRecord<>(KAFKA_TOPIC, responseData);
					
					producer.send(record, (metadata, exception) -> {
						if (exception == null) {
							System.out.println("Registro enviado para " + metadata.topic() + " particao " + metadata.partition() + " com offset " + metadata.offset());
						} else {
							exception.printStackTrace();
						}
					});
				} catch (Exception e) {
					e.printStackTrace();
				}

				Thread.sleep(5000);
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			producer.close();
		}
	}
}