# ANAC Flights Pipeline

Pipeline de dados de aviação civil brasileira construído com arquitetura medallion e infraestrutura na AWS.

## O que é

Este projeto coleta, processa e organiza os dados estatísticos de voos divulgados pela ANAC (Agência Nacional de Aviação Civil) e os disponibiliza em camadas progressivas de qualidade para análise — do CSV bruto até tabelas analíticas prontas para consumo no Amazon Athena.

## Por que existe

Dados públicos de aviação no Brasil são publicados em CSV com problemas de encoding, linha de metadados no cabeçalho, separadores ponto-e-vírgula e tipagem inadequada. Este pipeline automatiza o processo de ingestão e limpeza, tornando os dados confiáveis e prontos para consulta SQL.

## Como os dados fluem

```
ANAC (fonte pública — CSV ~47MB, 1,1M linhas)
        │
        ▼
   [ Bronze / S3 ]
   Dado bruto, exatamente como veio da fonte
   s3://anac-raw-{env}/dados_estatisticos/Dados_Estatisticos.csv
        │
        ▼
   [ Silver / S3 + Glue Catalog ]
   Parquet limpo, 38 colunas com nomes normalizados (snake_case),
   datas tipadas e decimal tratado
   s3://anac-silver-{env}/dados_estatisticos/Dados_Estatisticos.parquet
        │
        ▼
   [ Gold / Amazon Athena ]
   Modelos dbt com agregações analíticas prontas para consumo
   s3://anac-gold-{env}/
```

## Modelos analíticos (camada gold)

| Modelo | Descrição | Linhas |
|--------|-----------|--------|
| `fact_flights_by_airline` | Métricas por empresa, mês e natureza de voo (passageiros, decolagens, taxa de ocupação RPK/ASK) | ~39 mil |
| `fact_flights_by_route` | Volume e distância média por rota origem→destino | ~555 mil |
| `fact_flights_monthly` | Visão mensal consolidada do transporte aéreo brasileiro (2000–hoje) | ~642 |

## Cobertura dos dados

Série histórica de **2000 a 2026** com mais de **1,1 milhão de registros** cobrindo todas as empresas aéreas que operaram no Brasil — doméstico e internacional, regular e não regular.

## Ambientes

| Ambiente | Propósito |
|----------|-----------|
| `dev` | Desenvolvimento e validação de mudanças |
| `prod` | Dado confiável para consumo |

Toda mudança passa por `dev` antes de ir para `prod`. Promoção para produção exige aprovação manual no GitHub Actions.

## Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| Extração | Python + boto3 + requests |
| Armazenamento | AWS S3 |
| Catalogação | AWS Glue Data Catalog + Glue Crawler |
| Query engine | Amazon Athena |
| Orquestração | Apache Airflow 2.8.1 |
| Transformação | dbt-core 1.8.0 + dbt-athena-community 1.8.4 |
| Infraestrutura | Terraform (módulos S3 e Athena) |
| CI/CD | GitHub Actions (4 workflows) |

## CI/CD

| Workflow | Trigger | O que faz |
|----------|---------|-----------|
| `1-feature-pr-develop` | push `feature/**` / PR → develop | lint + testes + `tf plan` dev |
| `2-develop` | push `develop` (terraform/**) | `tf apply` dev automático |
| `3-production` | push `main` (terraform/**) | `tf apply` prod com aprovação manual |
| `4-hotfix` | push `hotfix/**` / PR → main | lint + testes |

## Estrutura

```
anac-flights-pipeline/
├── airflow/dags/         # DAG do Airflow (bronze >> silver >> gold)
├── ingestion/anac/
│   ├── bronze/           # extract.py — download e upload para S3
│   └── silver/           # transform.py — limpeza e conversão para Parquet
├── dbt/
│   ├── models/gold/      # 3 modelos analíticos
│   └── profiles.yml      # configuração do adapter Athena
└── terraform/
    ├── modules/s3/       # buckets bronze, silver e gold
    └── modules/athena/   # Glue databases, crawler e workgroup Athena
```

## Rodando localmente

```bash
# Subir o Airflow
docker-compose up -d

# Acessar a UI
open http://localhost:8080  # admin / airflow

# Variáveis de ambiente necessárias
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

O DAG `anac_pipeline` executa diariamente às 04h. Para rodar manualmente, acesse a UI e clique em **Trigger DAG**.
