# Guia de Instalação

Este documento fornece uma descrição passo a passo da instalação da infra, setup dos processos e execução do projeto [CRYPTO DATA MASTER] utilizando a [AWS] e [ELASTIC CLOUD].

## Pré-requisitos

A execução desse projeto prevê os seguintes pré-requisitos:

- Conta na nuvem **AWS** (gratuito - paga pelos recursos) - Após criação dos recursos, não esqueça de fazer o destroy da infra. O custo estimado dos recursos criados por 1 hora é de 5 dólares.
- Conta na Elastic **Cloud** (gratuito por 15 dias).
- Conta na plataforma **AlpacaMarket** (gratutito).
- Conta na plataforma **CoinAPI** (gratutito).
- Sistema operacional **Linux** - Ubuntu/Debian.
- Ferramentas - **Java**, **Python**, **VSCode** (pode ser outra IDE de sua escolha), **Terraform**, **AWS Cli**, **Ansible** e **Git** .

## Passo a Passo

### Passo 1: Criar uma conta na AWS

1. Visite [https://aws.amazon.com/pt/console/?nc1=h_ls].
2. Clique em **Faça login no console** e preencha os dados necessários.
3. No menu lateral da sua conta, escolha a opção **Credencias de segurança**. Em **Chaves de acesso**, crie uma nova e lembre-se de armazenar a *Chave de acesso* e *Chave de acesso secreta* em um local seguro. Utilizaremos ela para conectar na nossa conta via AWS Cli. Obs.: Será necessário cadastrar seu cartão, pois o projeto utiliza alguns recursos pagos.

### Passo 2: Criar uma conta no Elastic Cloud

1. Visite [https://www.elastic.co/pt/cloud].
2. Clique em **Iniciar avaliação gratuita**, responda às perguntas e inicie a criação de um cluster.
3. Quando o deployment terminar você pode excluí-lo clicando em **Manage**, depois selecione a opção **Delete deployment** em **Actions**.
4. No menu lateral da sua conta escolha a opção **Organization** e depois o menu **API Keys**.
5. Crie um API Key em **Create API key**, dê um nome adequado e marque a opção *Organization owner*. Copie a key em um local seguro.
6. Como utilizaremos a key no Terraform que é uma informação muito sensível, vamos voltar a AWS e armazenar esse valor no AWS Secret Manager. Na página inicial, busque por *Secrets Manager*, nesse projeto vou utilizar a região *us-east-1*.
7. No Secrets Manager escolha a opção **Armazenar um novo segredo**, selecione **Outro tipo de segredo**, como chave coloque **api-key-elastic-cloud-dm**, se colocar outro nome terá problemas na execução do projeto e não escolha uma região diferente da execução do Terraform, como valor coloque sua key do Elastic. Na segunda etapa coloque como nome **api_key_elastic_cloud_dm** Siga até a etapa final e clique em **Armazenar**.

### Passo 3: Criar uma conta na Alpaca Markets

1. Visite [https://docs.alpaca.markets/].
2. Escolha a opção **Trading Dashboard** e siga as instruções para criação da conta, você pode escolher como país os Estados Unidos.
3. Para habilitar qualquer opção, você precisa cadastrar uma autenticação multi fator, escolha *SMS* ou um *APP de Autenticação*.
4. Na **Home** do usuário, no canto inferior direito, tem um card chamado **API Keys**, clique em **Generate New Keys** e copie a Key e a Secret em um local seguro.

### Passo 4: Criar uma conta na CoinAPI

1. Visite [https://www.coinapi.io/].
2. Escolha a opção **Log in** e siga as instruções para conseguir o acesso.
3. Após conseguir acesso no menu lateral, escolha a opção **API Keys** e depois em **CREATE APIKEY**. Na lista, selecione **Market Data API** e então em **CREATE**. Armazene o valor em um local seguro.

### Passo 5: Instalação do Java

- Abra um terminal no Linux e execute o comando abaixo.
  - *sudo apt install openjdk-17-jre-headless*

### Passo 6: Instalação do Python 3

- Abra um terminal no Linux e execute o comando abaixo.
  - *sudo apt install python3 python3-pip python3-venv*

### Passo 7: Instalação do Visual Studio

- Você pode verificar as instruções atualizadas em [https://code.visualstudio.com/docs/setup/linux].
- Abra um **terminal no Linux** e execute a sequência de comandos abaixo.
  - *echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections*
  - *sudo apt-get install wget gpg*
  - *wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg*
  - *sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg*
  - *echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null*
  - *rm -f packages.microsoft.gpg*
  - *sudo apt install apt-transport-https*
  - *sudo apt update*
  - *sudo apt install code*

### Passo 8: Instalação do Terraform

- Você pode verificar as instruções atualizadas em [https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli].
- Escolha o sistema, em nosso caso vamos com o **Linux** distribuição *Ubuntu/Debian*
- Abra um **terminal no Linux** e execute a sequência de comandos abaixo.
  - *sudo apt-get update && sudo apt-get install -y gnupg software-properties-common*
  - *wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null*
  - *gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint*
  - *echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list*
  - *sudo apt update*
  - *sudo apt-get install terraform*

### Passo 9: Instalação do AWS Cli

- Você pode verificar as instruções atualizadas em [https://docs.aws.amazon.com/cli/v1/userguide/install-linux.html].
- Abra um **terminal no Linux** e execute a sequência de comandos abaixo.
  - *sudo apt  install curl*
  - *curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"*
  - *unzip awscliv2.zip*
  - *sudo ./aws/install*
- Após a instalação execute o comando *aws configure* e já *configure sua conta com o ID e Secret* que criou no **passo 1** e escolha a região **us-east-1**. Obs. Só para conhecimento, eles são armazenados na pasta ~/.aws, eles serão utilizados pelo Terraform.
  

### Passo 10: Instalação do Ansible

- Você pode verificar as instruções atualizadas em [https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu].
  - *sudo apt update*
  - *sudo apt install software-properties-common*
  - *sudo add-apt-repository --yes --update ppa:ansible/ansible*
  - *sudo apt install ansible*

### Passo 11: Instalação do Git, configuração e clone do projeto

- Você pode verificar as instruções atualizadas em [https://git-scm.com/book/pt-br/v2/Come%C3%A7ando-Instalando-o-Git].
  - *sudo apt-get install git-all*

- Para configurar sua conta do GitHub você pode seguir as instruções do próprio GitHub, visto que temos algumas alternativas, pode seguir a do seu gosto, no meu caso vou seguir essas:
  - *Criação de chave ssh*[https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent]
  - *Adicionando a chave na sua conta*[https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?tool=webui]

- Para deixar mais organizado, na sua home crie a pasta **projetos**. Mas claro que você pode seguir como quiser as etapas seguintes até o **passo 11**.
- No **VSCode** abra esta pasta, após isso, abra um terminal.
- Faça um clone do projeto:
  - *git clone git@github.com:stortieric/crypto-data-master.git*
  - *cd crypto-data-master/*
- Obs.: Verifique se os arquivos .zip na pasta programs não estão corrompidos. Caso estejam, faça o download manual do git.

### Passo 12: Execução do Projeto

- Crie um *ambiente virtual do Python* com os comandos.
  - *python3 -m venv venv-dm*
  - *source venv-dm/bin/activate*
- Instale os pacotes encontrados no requirements.txt com o comando *pip install -r requirements.txt*
- Agora abra o arquivo inventory.ini, ele é utilizado pelo Ansible e algumas informações precisam ser alteradas, já outras alteram automaticamente com a criação da infra.
- Na linha 5 altere o valor da variável **coin_api_key** para o valor que adquiriu no **passo 4**,
- Na linha 20 e 21 altere o valor das variáveis **alpaca_api_key** e **alpaca_secret_key**, adquiridos no **passo 3**.
- Importante, **não altere mais nada no arquivo, pois algumas informações são substituidas conforme a linha**.
- Na pasta roles/terraform/files/modules/sns temos o arquivo main.yml, que contém a configuração do recurso do SNS, nele eu configuro um e-mail para receber a notificação sobre os alarmes que configurei no projeto, no recurso *aws_sns_topic_subscription* altere a variável *endpoint* para seu e-mail.

- Vamos então à execução, primeiro vamos subir a **infra**, na raiz do projeto execute o comando:
  - *ansible-playbook -i inventory.ini -e "acao=deploy" deploy-infra-crypto.yml*
- A execução dura entre 30 minutos a 1 hora, se a execução ocorrer sem erros, vamos executar o próximo playbook para realizar o execução dos **processos**:
  - *ansible-playbook -i inventory.ini -e "acao=deploy" deploy-processos-crypto.yml* 

Se a execução ocorrer com **sucesso**, confira se os recursos na **AWS** e na **Elastic Cloud** foram criados e estão funcionando.

Tudo foi configurado para parar de executar após uma hora, assim evitamos custos adicionais, quando terminar de validar o funcionamento e atingiu seu objetivo, execute o playbook abaixo para derrubar toda infra e desta forma parar os processos.
 - *ansible-playbook -i inventory.ini -e "acao=destroy" deploy-infra-crypto.yml*

Em caso de dúvidas ou problemas, entre em contato através do meu e-mail [ericstorti@outlook.com].
