{{ config(
    materialized='incremental',
    unique_key='customer_id'
) }}

WITH cleaned_customers AS (
    SELECT 
        customer_id, 
        customer_unique_id, 
        COALESCE(customer_zip_code_prefix, 00000) AS customer_zip_code_prefix,  
        COALESCE(customer_city, 'Unknown') AS customer_city,  
        COALESCE(customer_state, 'Unknown') AS customer_state 
    FROM {{ source('raw', 'stg_customers_dataset') }}
)

SELECT * FROM cleaned_customers

{% if is_incremental() %}
WHERE customer_id NOT IN (SELECT customer_id FROM {{ this }})
{% endif %}
