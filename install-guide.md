# Guia de Instalação

Este documento fornece uma descrição passo a passo da instalação da infra, setup dos processos e execução do projeto [CRYPTO DATA MASTER] utilizando a [AWS] e [ELASTIC CLOUD].

## Pré-requisitos

A execução desse projeto prevê os seguintes pré-requisitos:

- Conta na cloud AWS (gratuito - paga pelos recursos)
- Conta na Elastic Cloud (gratuito por 15 dias)
- Conta na plataforma Alpaca (gratutito)
- Conta na plataforma CoinAPI (gratutito)
- Sistema operacional Linux - Ubuntu/Debian
- Ferramentas - Python, Ansible, Terraform, Git e VSCode (pode ser outra IDE de sua escolha)

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

### Passo 3: Desplegar o Projeto

1. No Painel de Controle, vá para **Desplegar Aplicação**.
2. Escolha a opção **Desplegar a partir do Repositório**.
3. Insira o URL do seu repositório [GitHub/GitLab/Outros] e clique em **Conectar**.

### Passo 4: Configurar Ferramentas de Gestão

1. Após a implantação, vá para **Configurações Avançadas**.
2. Configure integrações como:
   - **Monitoramento**: [Nome da Ferramenta]
   - **Backup Automático**: [Configurações relevantes]

### Passo 5: Testar a Instalação

1. Navegue até o endereço [URL do Projeto Desplegado].
2. Verifique se o aplicativo está funcionando corretamente.
3. Consulte os logs em **Visualizar Logs** se encontrar problemas.

## Temas e Fontes

- **Tema do Markdown:** Padrão escuro/claro conforme sua preferência.
- **Fonte:** Arial, 12pt.
- **Estilo de Cabeçalhos:** Negrito para seções principais, itálico se necessário.

## Suporte

Em caso de dúvidas ou problemas, entre em contato com nosso suporte técnico em [email ou fórum de suporte].

---

*Nota: Este é um modelo básico. Lembre-se de adaptar as instruções e informações específicas ao seu projeto e plataforma de nuvem.*
