{{ config(materialized='table') }}

SELECT
    ano,
    mes,
    natureza,
    COUNT(DISTINCT empresa_sigla)               AS total_empresas,
    SUM(passageiros_pagos + passageiros_gratis) AS total_passageiros,
    SUM(decolagens)                             AS total_decolagens,
    SUM(horas_voadas)                           AS total_horas_voadas,
    SUM(distancia_voada_km)                     AS total_distancia_voada_km,
    SUM(combustivel_litros)                     AS total_combustivel_litros
FROM {{ source('silver', 'dados_estatisticos') }}
GROUP BY 1, 2, 3
