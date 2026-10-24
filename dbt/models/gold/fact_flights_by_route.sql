{{ config(materialized='table') }}

SELECT
    ano,
    mes,
    origem_sigla,
    origem_nome,
    origem_uf,
    destino_sigla,
    destino_nome,
    destino_uf,
    natureza,
    SUM(passageiros_pagos + passageiros_gratis)                        AS total_passageiros,
    SUM(decolagens)                                                    AS total_decolagens,
    AVG(
        CAST(distancia_voada_km AS DOUBLE) / NULLIF(decolagens, 0)
    )                                                                  AS distancia_media_km
FROM {{ source('silver', 'dados_estatisticos') }}
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
