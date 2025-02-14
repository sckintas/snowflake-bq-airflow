{{ config(
    materialized='incremental',
    unique_key='seller_id'   
) }}

WITH cleaned_sellers AS (
    SELECT 
        seller_id, 
        COALESCE(seller_zip_code_prefix, 00000) AS seller_zip_code_prefix,   
        COALESCE(seller_city, 'Unknown') AS seller_city,   
        COALESCE(seller_state, 'Unknown') AS seller_state   
    FROM {{ source('raw', 'stg_sellers_dataset') }}
)

SELECT * FROM cleaned_sellers

{% if is_incremental() %}
WHERE seller_id NOT IN (SELECT seller_id FROM {{ this }})
{% endif %}
