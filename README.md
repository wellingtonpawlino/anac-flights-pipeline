# ANAC Flights Pipeline

Pipeline de dados de aviação civil brasileira construído com arquitetura medallion e infraestrutura na AWS.

## O que é

Este projeto coleta, processa e organiza os dados estatísticos de voos divulgados pela ANAC (Agência Nacional de Aviação Civil) e os disponibiliza em camadas progressivas de qualidade para análise.

## Por que existe

Dados públicos de aviação no Brasil são publicados em CSV com problemas de encoding, separadores inconsistentes e tipagem inadequada. Este pipeline automatiza o processo de ingestão e limpeza, tornando os dados confiáveis e prontos para consumo analítico.

## Como os dados fluem

```
ANAC (fonte pública)
        │
        ▼
   [ Bronze / S3 ]
   Dado bruto, exatamente como veio da fonte
        │
        ▼
   [ Silver / S3 ]
   Dado limpo, tipado e em formato Parquet
        │
        ▼
   [ Gold / futura camada ]
   Dado modelado para consumo por analistas e dashboards
```

## Ambientes

| Ambiente | Propósito |
|----------|-----------|
| `dev` | Desenvolvimento e validação de mudanças |
| `prod` | Dado confiável para consumo |

Toda mudança passa por `dev` antes de ir para `prod`. Promoção para produção exige aprovação manual.

## Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| Extração | Python + boto3 |
| Armazenamento | AWS S3 |
| Banco de dados | AWS RDS PostgreSQL 15 |
| Orquestração | Apache Airflow |
| Transformação | dbt |
| Infraestrutura | Terraform |
| CI/CD | GitHub Actions |

## Documentação técnica

Para detalhes de arquitetura, estrutura de arquivos e instruções de setup, consulte [docs/technical.md](docs/technical.md).
