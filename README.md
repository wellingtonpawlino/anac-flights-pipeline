# ANAC Flights Pipeline

![ANAC Flights Pipeline](assets/capa.png)

Pipeline de dados de aviação civil brasileira com arquitetura medallion no AWS.

Coleta o dataset estatístico da ANAC (~47 MB, 1,1 milhão de registros, série 2000–hoje), normaliza e estrutura em três camadas — Bronze, Silver e Gold — expondo tabelas analíticas prontas para consulta no Amazon Athena.

## Fluxo de dados

```
ANAC (CSV público, ~47 MB, 1,1M linhas)
        │
        ▼
   Bronze  ──  S3 (anac-raw-{env})
   CSV bruto, exatamente como veio da fonte
        │
        ▼
   Silver  ──  S3 + Glue Catalog (anac-silver-{env})
   Parquet limpo: 38 colunas snake_case, datas tipadas, decimal normalizado
        │
        ▼
   Gold  ──  Amazon Athena (anac-gold-{env})
   3 modelos analíticos prontos para consulta SQL
```

## Modelos analíticos (camada gold)

| Modelo | Descrição | Linhas aprox. |
|---|---|---|
| `fact_flights_by_airline` | Passageiros, decolagens e taxa de ocupação (RPK/ASK) por empresa e mês | ~39 mil |
| `fact_flights_by_route` | Volume e distância média por rota origem→destino | ~555 mil |
| `fact_flights_monthly` | Visão mensal consolidada do setor aéreo brasileiro (2000–hoje) | ~642 |

---

## Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) + Docker Compose
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.x configurado (`aws configure`)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- Conta AWS com permissões de criação de recursos S3, Glue, Athena e IAM

---

## Como executar

### 1. Clonar e configurar credenciais

```bash
git clone https://github.com/wellingtonpawlino/anac-flights-pipeline
cd anac-flights-pipeline
cp .env.example .env
```

Edite `.env` com suas credenciais AWS:

```
AWS_ACCESS_KEY_ID=seu_access_key
AWS_SECRET_ACCESS_KEY=seu_secret_key
```

### 2. Bootstrap: criar o bucket de state do Terraform (apenas uma vez)

O Terraform armazena o estado remotamente. Esse bucket precisa existir antes do `terraform init`:

```bash
aws s3api create-bucket \
  --bucket anac-flights-tfstate \
  --region sa-east-1 \
  --create-bucket-configuration LocationConstraint=sa-east-1
```

### 3. Provisionar a infraestrutura

```bash
cd terraform
terraform init -backend-config="key=dev/terraform.tfstate"
terraform apply -var-file=environments/dev.tfvars
cd ..
```

Recursos criados: 3 buckets S3 (bronze/silver/gold), Glue databases, Glue Crawler, Athena Workgroup e IAM role.

### 4. Subir o Airflow

```bash
docker-compose up -d
```

Aguarde ~30 segundos e acesse **http://localhost:8080**

```
usuário: admin
senha:   airflow
```

### 5. Executar o pipeline

**Via UI:** na DAG `anac_pipeline`, ative o toggle e clique em **Trigger DAG ▶**.

**Via linha de comando:**

```bash
docker exec anac_airflow_webserver airflow dags trigger anac_pipeline
```

O pipeline executa três tasks em sequência:

```
extract_bronze  ──►  transform_silver  ──►  run_gold_dbt
```

> **Primeira execução:** o dbt precisa que o Glue Catalog já tenha catalogado o Parquet da silver.
> Após `transform_silver` completar, execute o Glue Crawler manualmente e aguarde antes de acionar `run_gold_dbt`:
>
> ```bash
> # Disparar o crawler
> aws glue start-crawler --name anac-silver-dev --region sa-east-1
>
> # Verificar quando terminar (aguardar status READY)
> aws glue get-crawler \
>   --name anac-silver-dev \
>   --region sa-east-1 \
>   --query "Crawler.State" \
>   --output text
> ```
>
> Nas execuções seguintes o Catalog já existe e o pipeline roda sem intervenção.

### 6. Consultar os dados no Athena

Acesse o **Amazon Athena** no console AWS, selecione o workgroup `anac-dev` e o banco `anac_gold_dev`.

**Top 10 empresas por passageiros em 2024:**

```sql
SELECT
    empresa_nome,
    SUM(total_passageiros_pagos) AS passageiros
FROM fact_flights_by_airline
WHERE ano = 2024
GROUP BY empresa_nome
ORDER BY passageiros DESC
LIMIT 10;
```

**Rotas domésticas mais movimentadas:**

```sql
SELECT
    aeroporto_de_origem_sigla || ' → ' || aeroporto_de_destino_sigla AS rota,
    SUM(total_passageiros)                                            AS passageiros,
    ROUND(AVG(distancia_media_km), 0)                                 AS distancia_km
FROM fact_flights_by_route
WHERE natureza = 'DOMÉSTICA'
  AND ano = 2024
GROUP BY 1
ORDER BY passageiros DESC
LIMIT 10;
```

**Evolução anual do setor:**

```sql
SELECT
    ano,
    SUM(total_decolagens)   AS decolagens,
    SUM(total_passageiros)  AS passageiros
FROM fact_flights_monthly
GROUP BY ano
ORDER BY ano;
```

---

## Testes

```bash
pip install -r ingestion/anac/requirements.txt \
            -r ingestion/anac/requirements-dev.txt

pytest ingestion/anac/ -v
```

---

## Configurando para produção

1. Adicione os seguintes secrets no repositório GitHub:

   | Secret | Descrição |
   |---|---|
   | `AWS_ACCESS_KEY_ID` | Access key do IAM |
   | `AWS_SECRET_ACCESS_KEY` | Secret key do IAM |

2. Qualquer push para `main` com mudanças em `terraform/**` dispara o workflow de produção, que exige **aprovação manual** antes de aplicar.

3. Para provisionar o ambiente prod manualmente:

   ```bash
   cd terraform
   terraform init -backend-config="key=prod/terraform.tfstate"
   terraform apply -var-file=environments/prod.tfvars
   ```

---

## Estrutura do repositório

```
anac-flights-pipeline/
├── .github/workflows/
│   ├── 1-feature-pr-develop.yml   # lint + testes + terraform plan dev
│   ├── 2-develop.yml              # terraform apply dev (automático)
│   ├── 3-production.yml           # terraform apply prod (aprovação manual)
│   └── 4-hotfix.yml               # lint + testes
├── airflow/dags/
│   └── anac_pipeline.py           # DAG: bronze >> silver >> gold, schedule 04h
├── ingestion/anac/
│   ├── bronze/extract.py          # HTTP streaming → S3 bronze
│   └── silver/transform.py        # normalização + Parquet → S3 silver
├── dbt/
│   ├── models/gold/               # 3 modelos analíticos (SQL + schema.yml)
│   └── profiles.yml               # configuração do adapter Athena (dev/prod)
├── terraform/
│   ├── modules/s3/                # módulo reutilizável de bucket S3
│   ├── modules/athena/            # Glue databases, Crawler e Athena Workgroup
│   └── environments/              # dev.tfvars e prod.tfvars
├── docker-compose.yml             # Airflow 2.8.1 + PostgreSQL 15
└── docs/technical.md              # arquitetura detalhada e decisões técnicas
```

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Extração | Python · boto3 · requests |
| Armazenamento | AWS S3 |
| Catalogação | AWS Glue Data Catalog + Glue Crawler |
| Query engine | Amazon Athena |
| Orquestração | Apache Airflow 2.8.1 |
| Transformação | dbt-core 1.8.0 + dbt-athena-community 1.8.4 |
| Infraestrutura como código | Terraform >= 1.0 |
| CI/CD | GitHub Actions |
