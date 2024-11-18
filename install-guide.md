# Guia de Instalação

Este documento fornece uma descrição passo a passo da instalação da infra, setup dos processos e execução do projeto [CRYPTO DATA MASTER] utilizando a [AWS] e [ELASTIC CLOUD].

## Pré-requisitos

A execução desse projeto prevê os seguintes pré-requisitos:

- Conta na cloud AWS (gratuito - paga pelos recursos)
- Conta na Elastic Cloud (gratuito por 15 dias)
- Conta na plataforma Alpaca (gratutito)
- Conta na plataforma CoinAPI (gratutito)
- Sistema operacional Linux - Ubuntu/Debian
- Ferramentas - Python, Java, Ansible, Terraform, Git e VSCode (pode ser outra IDE de sua escolha)

## Passo a Passo

### Passo 1: Criar uma conta na AWS

1. Visite [https://aws.amazon.com/pt/console/?nc1=h_ls].
2. Clique em **Faça login no console** e preencha os dados necessários.
3. No menu lateral da sua conta escolha a opção **Credencias de segurança**. Em **Chaves de acesso** cria uma nova e lembre-se de armazenar a Chave de acesso e Chave de acesso secreta em um local seguro. Utilizaremos ela para logar na nossa conta via AWS Cli. Obs.: Será necessário cadastrar seu cartão, pois o projeto utiliza alguns recursos pagos.

### Passo 2: Criar uma conta no Elastic Cloud

1. Visite [https://www.elastic.co/pt/cloud].
2. Clique em **Iniciar avaliação gratuita**, resposta as perguntas e pode iniciar a criação do cluster.
3. Quando o deployment termninar você pode excluí-lo clicando em **Manage**, depois selecione a opção **Delete deployment** em **Actions**.
4. No menu lateral da sua conta escolha a opção **Organization** e depois o menu **API Keys**.
5. Crie um API Key em **Create API key**, dê um nome adequado e marque a opção *Organization owner*. Copie a key em um local adequado.
6. Como utilizaremos no Terraform e é uma informação muito sensível, vamos voltar a AWS e armazenar esse valor no AWS Secret Manager. Na página inicial busque por *Secrets Manager*, nesse projeto vou utilizar a região *us-east-1*.
7. No Secrets Manager escolha a opção **Armazenar um novo segredo**, selecione a opção **Outro tipo de segredo**, como chave coloque **api_key_elastic_cloud_dm**, se colocar outro nome terá problemas na execução do projeto e não escolha uma região diferente da execução do Terraform, como valor coloque sua key do Elastic. Siga até a etapa final e clique em **Armazenar**.

### Passo 3: Criar uma conta na Alpaca Markets

1. Visite [https://docs.alpaca.markets/].
2. Escolha a opção **Trading Dashboard** e siga as intruções para criação de conta, você pode escolher como país o Estados Unidos.
3. Para habilitar qualquer opção vocẽ precisa cadatrar uma autenticação multi fator, escolha *SMS* ou um *APP de Autenticação*.
4. Na *Home* do usuário, no canto inferior direito tem um card chamado **API Keys**, clique em **Generate New Keys** e copie a Key e a Secret em um local seguro.

### Passo 4: Criar uma conta na CoinAPI

1. Visite [https://www.coinapi.io/].
2. Escolha a opção **Log in** e siga as instruções para conseguir o acesso.
3. Após conseguir acesso no menu lateral escolha a opção **API Keys** e depois em **CREATE APIKET**. Na lista selecione **Market Data API** e então em **CREATE**. Armazene o valor em um local seguro.

### Passo 5: Instalação do Java

1. Abra um terminal no Linux e execute o comando abaixo.
2. ***sudo apt install openjdk-17-jre-headless**

## Passo 6: Instalação do Python 3

- Abra um terminal no Linux e execute o comando abaixo.
- **sudo apt-get install python3**

## Passo 7: Instalação do Visual Studio

- Você pode verificar as instruções atualizadas em [https://code.visualstudio.com/docs/setup/linux].
- Abra um terminal no Linux e execute a sequência de comandos abaixo.
  - echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
  - sudo apt-get install wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
  - sudo apt install apt-transport-https
    sudo apt update
    sudo apt install code

## Passo 7: Instalação do Terraform

- Você pode verificar as instruções atualizadas em [https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli].
- Escolha o sistema, em nosso caso vamos com o **Linux** distribuição *Ubuntu/Debian*
- Abra um terminal no Linux e execute a sequência de comandos abaixo.
  - sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
  - wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
  - gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint
  - echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
  - sudo apt update
  - sudo apt-get install terraform



-  
Em caso de dúvidas ou problemas, entre em contato com nosso suporte técnico em [email ou fórum de suporte].

---

*Nota: Este é um modelo básico. Lembre-se de adaptar as instruções e informações específicas ao seu projeto e plataforma de nuvem.*
