{{ config(
    materialized='incremental',
    partition_by={"field": "order_id", "data_type": "string"},   
    cluster_by=["payment_type"],   
    unique_key=["order_id", "payment_sequential"]
) }}

WITH base_payments AS (
    SELECT
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value,
        ROW_NUMBER() OVER (
            PARTITION BY order_id ORDER BY payment_value DESC  -- ✅ Fixed syntax issue
        ) AS row_num
    FROM {{ source('raw', 'stg_order_payments_dataset') }}
)

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM base_payments
WHERE row_num = 1  

{% if is_incremental() %}
AND order_id NOT IN (SELECT order_id FROM {{ this }})  -- ✅ Fixed incremental logic
{% endif %}
