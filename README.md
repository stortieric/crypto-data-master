# Projeto de Dados 

# ![bitcoin](https://s3.eu-central-1.amazonaws.com/bbxt-static-icons/type-id/png_32/4caf2b16a0174e26a3482cea69c34cba.png) Crypto Data Master ![litecoin](https://s3.eu-central-1.amazonaws.com/bbxt-static-icons/type-id/png_32/a201762f149941ef9b84e0742cd00e48.png)

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


[Descreva a arquitetura de alto nível do sistema, focando nos principais componentes e suas interações. Utilize um diagrama para visualizar a arquitetura.  Sugiro utilizar o **draw.io** (ferramenta online gratuita e fácil de usar) ou o **Lucidchart** (com opções gratuitas e pagas) para criar diagramas UML (Unified Modeling Language) ou diagramas de blocos.  Um diagrama de contexto também seria útil.]

*(Insira aqui o diagrama de solução. Salve-o como uma imagem (PNG ou SVG) e adicione-a ao repositório.  Link o diagrama aqui no README usando o Markdown: `![Diagrama de Solução](diagrama_solucao.png)`)

**Arquitetura Técnica:**

[Descreva a arquitetura técnica detalhada, incluindo tecnologias utilizadas (banco de dados, linguagens de programação, frameworks, etc.), infraestrutura (cloud, on-premise), e a estrutura de desenvolvimento (ex: microsserviços, monólito). Utilize um diagrama para visualizar a arquitetura técnica.  O **draw.io** ou **Lucidchart** são ótimas opções para este diagrama também. Considere diagramas de componentes, diagramas de implantação ou diagramas de sequência, conforme aplicável.]

*(Insira aqui o diagrama de arquitetura técnica.  Salve-o como uma imagem (PNG ou SVG) e adicione-a ao repositório. Link o diagrama aqui no README usando o Markdown: `![Diagrama de Arquitetura Técnica](diagrama_tecnico.png)`)


## III. Explicação sobre o Case Desenvolvido

[Descreva detalhadamente o desenvolvimento do projeto. Inclua informações sobre o processo de coleta, tratamento e análise de dados.  Explique as etapas principais do desenvolvimento e as decisões tomadas ao longo do processo. Use subseções para organizar melhor a informação.  Seja preciso e evite jargões técnicos excessivos a menos que sejam essenciais para a compreensão.]

**Exemplo de Subseções:**

* **Coleta de Dados:** [Explicação da origem dos dados e métodos de coleta.]
* **Pré-processamento de Dados:** [Limpeza, transformação e preparação dos dados para análise.]
* **Modelagem e Análise:** [Descrição dos modelos utilizados e os resultados obtidos.]
* **Implementação:** [Detalhes da implementação, incluindo tecnologias e metodologias.]


## IV. Melhorias e Considerações Finais

[Descreva potenciais melhorias para o projeto e as considerações finais.  Liste as limitações encontradas e como elas poderiam ser superadas em futuras iterações.  Reflita sobre o aprendizado obtido durante o desenvolvimento do projeto.]

**Exemplo:**  *Melhorias futuras poderiam incluir a integração com outras fontes de dados para enriquecer a análise.  Uma limitação foi a disponibilidade de recursos computacionais, que poderia ser melhorada utilizando uma solução em nuvem com maior capacidade de processamento.*


## Contribuições

[Liste os membros da equipe e suas contribuições para o projeto.]


## Licença

[Indique a licença do projeto, por exemplo, MIT License.]
