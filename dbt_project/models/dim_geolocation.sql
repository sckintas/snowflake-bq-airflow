{{ config(
    materialized='incremental',
    unique_key='geolocation_zip_code_prefix'   
) }}

WITH ranked_geolocation AS (
    SELECT 
        geolocation_zip_code_prefix,
        COALESCE(geolocation_lat, 0.0) AS geolocation_lat,   
        COALESCE(geolocation_lng, 0.0) AS geolocation_lng,
        COALESCE(geolocation_city, 'Unknown') AS geolocation_city,
        COALESCE(geolocation_state, 'Unknown') AS geolocation_state,
        ROW_NUMBER() OVER (
            PARTITION BY geolocation_zip_code_prefix ORDER BY geolocation_lat ASC
        ) AS row_num   
    FROM {{ source('raw', 'stg_geolocation_dataset') }}
)

SELECT 
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM ranked_geolocation
WHERE row_num = 1   

{% if is_incremental() %}
AND geolocation_zip_code_prefix NOT IN (SELECT geolocation_zip_code_prefix FROM {{ this }})
{% endif %}
