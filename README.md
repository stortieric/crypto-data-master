# Projeto de Dados 

# ![bitcoin](https://s3.eu-central-1.amazonaws.com/bbxt-static-icons/type-id/png_32/4caf2b16a0174e26a3482cea69c34cba.png) Crypto DM ![litecoin](https://s3.eu-central-1.amazonaws.com/bbxt-static-icons/type-id/png_32/a201762f149941ef9b84e0742cd00e48.png)

**Repositório:** [https://github.com/stortieric/crypto-data-master]

## I. Objetivo do Case

Este case tem por objetivo a criação de um Lake na AWS que armazenará informações sobre criptomoedas. Com certeza é um mercado que atrai investimento e o fato de poder tomar decisão em tempo real é um grande incentivo para este projeto. 

Como premissa, o projeto prevê todas informações possíveis sendo recebidas em tempo real, a dificuldade se torna grande, pois administrar processos em tempo real gera grande esforço, por isso, precisamos de uma infraestrutra confíável que encontramos na AWS. Apesar de toda a infra ser AWS utilizadmos o serviço Elastic Cloud que gerencia melhor os recursos Elasticsearch e Kibana, para utiliza-los precisamos escolher uma cloud como provedora, em nosso caso seguimos com AWS na mesma região que outros recursos para diminuir a latência.

O projeto contém processos de coleta de dados da API Alpaca Market que fornece uma śerie de informações de cripto, além de outras ações. Inclusive é possível brincar de Trader com um saldo fictício na plataforma. Em nosso caso vamos consumir uma API com dados de cotação atualizados de minuto em minuto e de duas moedas, o Bitcoin e o Litecoin, podemos incluir outras, mas para nosso case vamos testar com duas.

Como informação pública pessoal encontramos apenas em sites suspeitos na internet, vamos simular a compra e venda de cripto, o usuario escolhe comprar ou vender e de acordo com o horário podemos saber o valor de compra/venda por usuário. 

Para ambos os casos consumimos dados em tempo real, desta forma poderemos ter o volume de venda e compra de cripto em pouco minutos. Para você que gosta de um dashboard, vamos consumir uma API da CoinAPI que armazena o logo de cada cripto ou moeda comum disponível no mercado, assim poderá utilizar os valores contidos na url para criar um dashboard mais atraente. 

Sem mais, vamos discutir um pouco sobre a nossa arquitetura de solução e arquitetura técnica.

## II. Arquitetura de Solução e Arquitetura Técnica

![solucao](https://github.com/stortieric/crypto-data-master/blob/main/architecture/arquitetura-crypto-dm-solucao.png)

Para possibilitarmos o acompanhamento dos dados de cripto em tempo real a solução é criamos um consumer que envia os dados para um broker, em nosso caso o MSK, que nada mais é que um serviço de Kafka gerenciado pela AWS, ele recebe os dados da API da Alpaca e dos dados simulados do trader. Como a informação de logo das moedas não atualizam com tanta frequência, optamos por utilizar uma função lambda que atualizará esses dados uma vez ao dia.

O MSK é um serviço que suporta muito bem grande volume de dados, por isso uma boa escolha. Como nosso caso tem um foco mais analítico, utilizamos o serviço do EMR (Elastic Map Reduce) para provisionar os clusters Spark. Assim consumimos os dados que estão sendo recebidos no Kafka e enviamos os dados para o S3, para armazenamento e consumo analítico via Athena, que é uma engine de processamento Serveless bem robusta. Em um destes processos enviamos os dados para o Elasticsearch, o objetivo é que possa consultar esse índice em tempo real para alimentar um dashbord no Kibana.

Muito importante citar que utizamos o Glue como nosso catálogo de dados e como formato de tabela o Iceberg, este último é muito parecido com o formato Delta, facilitando o processo de evolução dos dados.

Para nossa segurança os dados na AWS são criptografados, assim garantimos mais segurança no armazenamento dos dados.

Com o uso do Cloudwatch podemos monitorar os recursos criamos na AWS, além de customizar alertas e utilizar o o serviço SNS para envio de notificação.

O Macie provẽ uma solução em Machine Learning que ajuda a identificar, monitorar e proteger os dados sensíveis armazenados no S3, com ele habilitado a descoberta é feita de forma automática.

Nosss arquitetura se assemelha a Kappa, pois tem como premissa a atualização de dados em tempo real, mas podemos combina-la com arquitetura medalhão que fornece uma governança melhor.

![tecnico](https://github.com/stortieric/crypto-data-master/blob/main/architecture/arquitetura-crypto-dm-tecnica.png)

Vamos abordar agora uma visão mais técnica da arquitetura, todos os recurso do projeto são criados na AWS, na própria AWS e via Elastic Cloud. A região escolhida em ambos os casos é a us-east-1.

Para criar e destruir os recursos automaticamente utilizei o Terraform, ideal para automação de infra em provedores de Cloud. Combinamos o Terraform com o Ansible, já este é ideal automação de processos dentro dos recursos, VMs, Docker, etc... Com os dois é possível salvar um bom tempo ao criar os recursos com um Enter no terminal e eliminar os recursos após os testes.

O recurso EC2 que conecto via local é utilizado para criar os tópicos e executar os producers Kafka, o mesmo está em uma subnet pública com um internet gateway, possibilitando a conexão com minha máquina local.

A instância EC2 conecta no MSK via SASL_SSL/IAM, que com a devida role e politica conecta no Kafka para alimentação dos tópicos. 

Dentro das instâncias EMR, realizamos o submit dos jobs em Spark/Scala, a autenticação no Kafka também é via SASL_SSL/IAM, para o job que grava os dados no Elasticsearch utilizamos a autenticação por usuário e senha.

Agendamos via Event Bridge o job de atualização dos ícones da moedas e também um que faz semanalmente a otimização das tabelas Iceberg, visto que tratamos de dados em streming, precisamos evitar um velho problema com small files.

Os recursos EC2, EMR e MSK são gerenciados pelo cliente, por isso os mesmo estão em uma VPC com seus respectivos grupos de segurança configurados, garantindo apenas a comunicação entre eles e nossa máquina local.

Todos os outros recursos são gerenciados pela AWS, por isso existe apenas a necessidade de configuração de roles, grupos e usuários, a infra é gerenciada pela AWS.

O Elastic Cloud fornece a opção de escolha do provedor de cloud, região e quantidade de zonas de disponibilidades, fora isso, temos a necessidade também de configurar devidamente os acessos.

## III. Explicação sobre o Case Desenvolvido

Agora vamos explicar com maiores detalhes o case desenvolvido, para isso vamos em etapas.

* **Ingestão:**

Na etapa de ingestão pensamos na melhor estratégia que se encaixava em nosso case, a escolha foi criação de dois producers em JAVA. O ProducerCrypto-1.0.jar tem como objetivo conectar na API da Alpaca e atualizar a cada 5 segundos os dados de cotação de cripto. O ProducerTrader-1.0.jar simula dados de compra e venda de cripto. Os dois são enviados para um tópico Kafka cada um, os tópicos coinbase-currencies e coinbase-trades, respectivamente.

A criação dos tópicos e execução dos processos em Java são realizados na intância EC2 que configuramos via Terrafom, o processo salva e chave ssh na em nosso local, toda configuração é feita via Ansible.

Uma das etapa do playbook deploy-processos-crypto ansible é automatizar a criação das tabelas no catálogo Glue e realizar uma carga porntual da tabela crypto_db.crypto_assets. No Terraform configuramos duas funções Lambda que realizam a execução serveless desses processos, no caso da atualização da tabela crypto_db.crypto_assets agendamos um regra no Event Bridge que executará esse processo uma vez ao dia.

* **Processamento:**

Sobre o processamento feito em função Lambda da tabela crypto_db.crypto_assets falamos no tópico anterior, agora vamos falar sobre o EMR.

Essa foi a escolha para processamento dos nossos jobs em Spark/Scala. O EMR não é um recurso exclusivo para processamento Spark, podemos configurar um cluster Flink, Hive e Presto, por exemplo. 

Temos 3 jobs para executar em Spark, o KafkaConsumerCryptoS3-1.0.jar que consome os dados do tópico Kafka coinbase-currencies e os envia para o S3 em formato Iceberg e atualiza a tabela crypto_db.crypto_quote. Temos um job semelhante a este chamado KafkaConsumerCryptoElastic-1.0.jar porém seu destino é outro, enviamos os dados para o Elasticsearch e criamos automaticamente um índice chamado CRYPTO_QUOTE, o mesmo será utilizado no relatório de acompanhamento de cripto.

* **Armazenamento:**

Os dados são armazenados no S3, criamos 3 buckets: bronze-iceberg-data, silver-iceberg-data e gold-iceberg-data, cada um será responsável por armazenar um tipo de informação. Em nosso case alimentamos apenas a camada bronze, criamos um database no Glue chamado crypto_db. Levando em consideração e evolução dos nossos dados escolhemos o formato Iceberg, sabemos que um arquivo parquet é imutável, assim precisamos de um formato que seja mais flexível.

O formato Iceberg permite schema evolution, time travel, além de outros. Uma das vantagens em relação ao Delta é o partition evolution, na minha visão é importante, pois com o tempo, conforme a necessidade de negócio ou performance precisamos adotar uma estratégia difente para otimização da leitura.

* **Governança:**



* **Segurança:**


* **Observabilidade:**






## IV. Melhorias e Considerações Finais

[Descreva potenciais melhorias para o projeto e as considerações finais.  Liste as limitações encontradas e como elas poderiam ser superadas em futuras iterações.  Reflita sobre o aprendizado obtido durante o desenvolvimento do projeto.]

**Exemplo:**  *Melhorias futuras poderiam incluir a integração com outras fontes de dados para enriquecer a análise.  Uma limitação foi a disponibilidade de recursos computacionais, que poderia ser melhorada utilizando uma solução em nuvem com maior capacidade de processamento.*


## Contribuições

[Liste os membros da equipe e suas contribuições para o projeto.]


## Licença

[Indique a licença do projeto, por exemplo, MIT License.]
