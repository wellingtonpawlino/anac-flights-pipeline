{{ config(materialized='table') }}

SELECT
    ano,
    mes,
    empresa_sigla,
    empresa_nome,
    empresa_nacionalidade,
    natureza,
    grupo_de_voo,
    SUM(passageiros_pagos)                                          AS total_passageiros_pagos,
    SUM(passageiros_gratis)                                         AS total_passageiros_gratis,
    SUM(passageiros_pagos + passageiros_gratis)                     AS total_passageiros,
    SUM(decolagens)                                                 AS total_decolagens,
    SUM(horas_voadas)                                               AS total_horas_voadas,
    SUM(distancia_voada_km)                                         AS total_distancia_voada_km,
    SUM(ask)                                                        AS total_ask,
    SUM(rpk)                                                        AS total_rpk,
    CASE
        WHEN SUM(ask) > 0
        THEN ROUND(CAST(SUM(rpk) AS DOUBLE) / SUM(ask), 4)
        ELSE NULL
    END                                                             AS taxa_ocupacao
FROM {{ source('silver', 'dados_estatisticos') }}
GROUP BY 1, 2, 3, 4, 5, 6, 7
