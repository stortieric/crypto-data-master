**bitcoin**  
**Crypto**  
**DM**  
**litecoin**

Repositório: [https://github.com/stortieric/crypto-data-master](https://github.com/stortieric/crypto-data-master)

## I. Objetivo do Case

Este case tem como objetivo a criação de um **data lake** na AWS que armazenará informações sobre criptomoedas. O mercado de criptomoedas atrai investimentos, e a possibilidade de tomada de decisão em tempo real é um grande incentivo para este projeto.

Como premissa, o projeto prevê o recebimento de todas as informações possíveis em tempo real. A administração de processos em tempo real apresenta grande complexidade, exigindo uma infraestrutura confiável como a oferecida pela AWS. Embora toda a infraestrutura seja AWS, utilizamos o serviço **Elastic Cloud** para melhor gerenciamento dos recursos **Elasticsearch** e **Kibana**. Para utilizá-los, precisamos escolher um provedor de cloud; neste caso, mantivemos a AWS na mesma região de outros recursos para reduzir a latência.

O projeto inclui processos de coleta de dados da **API Alpaca Markets**, que fornece uma série de informações sobre criptomoedas e outras ações. A plataforma permite até mesmo simular operações de trading com um saldo fictício. Em nosso caso, consumiremos uma API com dados de cotação atualizados a cada minuto para duas moedas: **Bitcoin** e **Litecoin**. Outras moedas podem ser incluídas posteriormente, mas, para este case, testaremos com apenas duas.

Como informações públicas sobre negociações individuais são difíceis de encontrar em fontes confiáveis, simularemos a compra e venda de criptomoedas. O usuário escolhe comprar ou vender, e o valor da transação é determinado pelo horário da operação.

Para ambos os casos (API Alpaca e simulação de trading), consumimos dados em tempo real, permitindo o acompanhamento do volume de compra e venda em poucos minutos. Para a criação de um dashboard mais atraente, utilizaremos uma API da **CoinAPI** que fornece os logos das criptomoedas e moedas comuns disponíveis no mercado.

A seguir, discutiremos a arquitetura de solução e a arquitetura técnica.

## II. Arquitetura de Solução e Arquitetura Técnica

### Solução

Para o acompanhamento em tempo real dos dados de criptomoedas, criamos um **consumer** que envia os dados para um **broker** (MSK – serviço Kafka gerenciado pela AWS). O MSK recebe os dados da API Alpaca e os dados simulados do trader. Como as informações de logo das moedas não são atualizadas com tanta frequência, optamos por utilizar uma função **Lambda** para atualizar esses dados diariamente.

O MSK suporta grandes volumes de dados, tornando-o uma boa escolha. Como nosso foco é analítico, utilizamos o **EMR** (Elastic Map Reduce) para provisionar clusters Spark. Assim, consumimos os dados do Kafka e os enviamos para o **S3** para armazenamento e consumo analítico via **Athena** (uma engine de processamento serverless robusta). Durante este processo, também enviamos os dados para o **Elasticsearch** para consultas em tempo real e alimentação do dashboard **Kibana**.

Utilizamos o **Glue** como catálogo de dados e o formato de tabela **Iceberg** (similar ao Delta), facilitando a evolução dos dados.

Para segurança, os dados na AWS são criptografados. O **CloudWatch** monitora os recursos, permite customizar alertas e, através do **SNS**, enviar notificações. O **Macie** utiliza Machine Learning para identificar, monitorar e proteger dados sensíveis no S3.

Nossa arquitetura se assemelha à **Kappa**, por priorizar atualização em tempo real, mas pode ser combinada com a arquitetura **Medalhão** para melhor governança.

### Técnico

Abordaremos agora uma visão técnica da arquitetura. Todos os recursos são criados na AWS e via **Elastic Cloud** na região **us-east-1**.

O **Terraform** automatiza a criação e destruição de recursos. O **Ansible** automatiza processos internos (VMs, Docker, etc.). A combinação dos dois otimiza o tempo de criação e remoção de recursos.

A instância **EC2** (conectada localmente) cria os tópicos e executa os producers Kafka. Ela está em uma subnet pública com internet gateway.

A instância **EC2** conecta ao **MSK** via **SASL_SSL/IAM**. As instâncias **EMR** executam os jobs **Spark/Scala**, com autenticação via **SASL_SSL/IAM** para o Kafka e autenticação por usuário e senha para o Elasticsearch.

O **Event Bridge** agenda a atualização dos ícones das moedas e a otimização semanal das tabelas Iceberg (para evitar problemas com small

files em dados de streaming).

Os recursos **EC2**, **EMR** e **MSK** são gerenciados pelo cliente, estando em uma **VPC** com seus respectivos grupos de segurança configurados. Outros recursos são gerenciados pela AWS, necessitando apenas de configuração de roles, grupos e usuários.

O **Elastic Cloud** permite a escolha do provedor de cloud, região e zonas de disponibilidade.

## III. Explicação sobre o Case Desenvolvido

Descreveremos o case em etapas:

### Ingestão

A ingestão é feita por dois producers em Java: `ProducerCrypto-1.0.jar` (conecta-se à API Alpaca e atualiza os dados de cotação a cada 5 segundos) e `ProducerTrader-1.0.jar` (simula dados de compra e venda). Ambos enviam dados para tópicos Kafka (`coinbase-currencies` e `coinbase-trades`, respectivamente).

A criação dos tópicos e a execução dos processos Java são realizados na instância **EC2** (configurada via Terraform e Ansible). Um playbook Ansible (`deploy-processos-crypto`) automatiza a criação das tabelas no catálogo **Glue** e a carga inicial da tabela `crypto_db.crypto_assets`. Duas funções **Lambda** executam esses processos; a atualização da tabela `crypto_db.crypto_assets` é agendada no **Event Bridge** para execução diária.

### Processamento

O processamento da tabela `crypto_db.crypto_assets` (via Lambda) foi descrito anteriormente. O **EMR** processa os jobs **Spark/Scala**.

Existem três jobs Spark: 
- `KafkaConsumerCryptoS3-1.0.jar` (consome dados do tópico `coinbase-currencies` e envia para o S3 em formato Iceberg, atualizando a tabela `crypto_db.crypto_quote`);
- `KafkaConsumerCryptoElastic-1.0.jar` (semelhante ao anterior, mas envia os dados para o **Elasticsearch**, criando o índice **CRYPTO_QUOTE**);
- Um job para otimização semanal das tabelas **Iceberg**.

### Armazenamento

Os dados são armazenados em três buckets **S3** (`bronze-iceberg-data`, `silver-iceberg-data`, `gold-iceberg-data`). Neste case, alimentamos apenas a camada **bronze**, criando um banco de dados no **Glue** chamado `crypto_db`. O formato **Iceberg** foi escolhido por sua flexibilidade (schema evolution, time travel, partition evolution).

Um job **Lambda** otimiza as tabelas semanalmente.

### Consumo

O data lake tem duas fontes de armazenamento: **S3** (via **Athena**) e **Elasticsearch** (via **Kibana**). O dashboard **Kibana** ("Crypto Cotação de Mercado") acompanha a atualização de preços em tempo real.

### Governança

A governança utiliza o **Glue** (armazenamento de metadados, controle de acesso, crawlers), o **Macie** (identificação de dados sensíveis) e políticas **IAM**.

### Segurança

A segurança inclui **VPC**, grupos de usuários com políticas **IAM** específicas, criptografia **SSE-S3** para dados no **S3** e o monitoramento do **Macie**.

### Observabilidade

O **CloudWatch** monitora os recursos **EC2**, **MSK** e **EMR**. Alertas customizados são configurados e enviados via **SNS**. Tags ("crypto-lake") são usadas para melhor identificação dos recursos.

## IV. Considerações Finais

Este projeto demonstra a construção de um **data lake** robusto e eficiente para o processamento de dados de criptomoedas em tempo real. No entanto, existem áreas para melhoria contínua:

- **Containerização dos Jobs Java**: A migração dos producers Java para contêineres Docker e sua orquestração via serviços como o **Elastic Beanstalk** ou o **ECS** melhoraria a escalabilidade, a manutenção e a portabilidade da solução.
  
- **Orquestração dos Jobs Spark via Glue**: A utilização dos **Glue Jobs** para orquestrar os jobs Spark permitiria uma gestão mais integrada e simplificada do fluxo de processamento de dados.

- **Refinamento das Políticas IAM**: Uma revisão detalhada das políticas **IAM**, com o objetivo de aplicar o princípio do menor privilégio, aumentaria a segurança da solução e reduziria a superfície de ataque.

- **Monitoramento e Alerta Aprimorado**: A implementação de um sistema de monitoramento e alerta mais abrangente, que inclua métricas de performance detalhadas e alertas proativos para diferentes cenários de falha, contribuiria para maior estabilidade e confiabilidade do sistema.

- **Integração com Ferramentas CI/CD**: A integração com ferramentas **CI/CD** (Integra Continuous Integration/Continuous Delivery) automatizaria o processo de build, teste e deploy da solução, garantindo um ciclo de vida de desenvolvimento mais ágil e eficiente.

A implementação dessas melhorias garantirá uma solução mais robusta, escalável e segura. O projeto está aberto a contribuições e sugestões para aprimoramentos futuros.


