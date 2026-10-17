# Documentação Técnica

## Arquitetura

O pipeline segue a arquitetura **medallion** com três camadas de dado armazenadas no AWS S3:

- **Bronze** (`anac-raw-{env}`) — CSV bruto da ANAC, sem transformações
- **Silver** (`anac-silver-{env}`) — dado limpo e tipado em Parquet
- **Gold** (`anac-gold-{env}`) — agregações e modelos para consumo analítico (a implementar com dbt)

O banco de dados RDS PostgreSQL serve como destino final para modelos dbt e consumo por ferramentas de BI.

## Estrutura do repositório

```
anac-flights-pipeline/
├── .github/workflows/
│   ├── 1-feature-pr-develop.yml   # lint + testes + terraform plan dev
│   ├── 2-develop.yml              # terraform apply dev (automático)
│   ├── 3-production.yml           # terraform apply prod (aprovação manual)
│   └── 4-hotfix.yml               # lint + testes para hotfix
├── ingestion/anac/
│   ├── bronze/
│   │   ├── extract.py             # download da ANAC e upload para S3
│   │   └── test_extract.py
│   ├── silver/
│   │   ├── transform.py           # limpeza, tipagem e escrita em Parquet
│   │   └── test_transform.py
│   ├── requirements.txt
│   └── requirements-dev.txt
├── terraform/
│   ├── modules/
│   │   ├── s3/                    # módulo reutilizável de bucket S3
│   │   └── rds/                   # módulo de instância RDS PostgreSQL
│   ├── environments/
│   │   ├── dev.tfvars
│   │   └── prod.tfvars
│   ├── backend.tf                 # estado remoto no S3
│   ├── main.tf                    # composição dos módulos
│   ├── variables.tf
│   └── outputs.tf
├── airflow/dags/                  # DAGs de orquestração (a implementar)
└── dbt/                           # modelos da camada gold (a implementar)
```

## Camada Bronze — extract.py

Baixa o arquivo `Dados_Estatisticos.csv` da API pública da ANAC via HTTP streaming e faz upload direto para o bucket S3 bronze sem tocar em disco.

```
ANAC API → requests.get(stream=True) → s3.upload_fileobj → anac-raw-{env}
```

## Camada Silver — transform.py

Lê o CSV da bronze, aplica transformações e escreve Parquet na silver.

**Transformações aplicadas:**
- Encoding `latin-1` e separador `;` tratados na leitura
- Nulos representados por `-`, `--`, `—`, `N/A` convertidos para `NaN`
- Espaços extras em colunas de texto removidos com `str.strip()`
- Colunas no formato `dd/mm/yyyy` convertidas para `datetime64`
- Saída em Parquet com `pyarrow` (schema embutido, compressão eficiente)

## Infraestrutura — Terraform

Dois módulos reutilizáveis:

**`modules/s3`** — cria um bucket com:
- Criptografia AES-256 ativada
- Bloqueio total de acesso público

**`modules/rds`** — cria uma instância PostgreSQL 15 com:
- `db.t3.micro` (free tier)
- Security group restrito ao CIDR configurado
- Criptografia em repouso ativada

O estado do Terraform é armazenado no bucket `anac-flights-tfstate` com lock nativo (sem DynamoDB).

Cada ambiente usa um arquivo de variáveis separado e uma chave de state isolada:
- Dev: `key=dev/terraform.tfstate`
- Prod: `key=prod/terraform.tfstate`

## GitFlow e CI/CD

```
feature/** ──► PR → develop ──► develop ──► PR → main ──► main
                   │                              │
              plan dev                       plan prod
                                            (aprovação manual)
hotfix/** ──► PR → main / develop
```

| Workflow | Trigger | O que faz |
|----------|---------|-----------|
| `1-feature-pr-develop` | push `feature/**` / PR → `develop` | lint, testes, terraform plan dev |
| `2-develop` | push `develop` (mudanças em `terraform/**`) | terraform apply dev |
| `3-production` | push `main` (mudanças em `terraform/**`) | terraform apply prod com aprovação |
| `4-hotfix` | push `hotfix/**` / PR → `main` ou `develop` | lint e testes |

## Setup

### Pré-requisitos

- AWS CLI configurado com credenciais de um usuário IAM com `AdministratorAccess`
- Terraform >= 1.0 instalado
- Python 3.11

### 1. Criar o bucket de state (uma vez)

```bash
aws s3api create-bucket \
  --bucket anac-flights-tfstate \
  --region sa-east-1 \
  --create-bucket-configuration LocationConstraint=sa-east-1
```

### 2. Configurar secrets no GitHub

| Secret | Descrição |
|--------|-----------|
| `AWS_ACCESS_KEY_ID` | Access key do usuário IAM |
| `AWS_SECRET_ACCESS_KEY` | Secret key do usuário IAM |
| `DB_PASSWORD` | Senha do RDS |
| `ALLOWED_CIDR` | IP autorizado a conectar no RDS (ex: `0.0.0.0/0` para estudo) |

### 3. Provisionar infraestrutura dev

```bash
cd terraform
terraform init -backend-config="key=dev/terraform.tfstate"
terraform apply -var-file=environments/dev.tfvars \
  -var="db_password=sua-senha" \
  -var="allowed_cidr=0.0.0.0/0"
```

### 4. Rodar os testes localmente

```bash
pip install -r ingestion/anac/requirements.txt
pip install -r ingestion/anac/requirements-dev.txt
pytest ingestion/anac/bronze/ ingestion/anac/silver/
```

## Decisões de arquitetura

| Decisão | Motivo |
|---------|--------|
| Bucket S3 separado por camada | Isolamento de acesso, custo e lifecycle independentes |
| Parquet na silver | Schema embutido, compressão eficiente, padrão do mercado |
| tfvars por ambiente | Reutilização do mesmo código Terraform em dev e prod |
| State S3 com lock nativo | Sem custo de DynamoDB, disponível desde Terraform 1.10 |
| `db.t3.micro` | Free tier elegível para ambiente de estudo/portfólio |
