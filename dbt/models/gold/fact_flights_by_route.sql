{{ config(materialized='table') }}

SELECT
    ano,
    mes,
    aeroporto_de_origem_sigla,
    aeroporto_de_origem_nome,
    aeroporto_de_origem_uf,
    aeroporto_de_destino_sigla,
    aeroporto_de_destino_nome,
    aeroporto_de_destino_uf,
    natureza,
    SUM(passageiros_pagos + passageiros_gratis)                        AS total_passageiros,
    SUM(decolagens)                                                    AS total_decolagens,
    AVG(
        CAST(distancia_voada_km AS DOUBLE) / NULLIF(decolagens, 0)
    )                                                                  AS distancia_media_km
FROM {{ source('silver', 'dados_estatisticos') }}
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
