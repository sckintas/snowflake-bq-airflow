{{ config(
    materialized='incremental',
    partition_by={"field": "order_purchase_timestamp", "data_type": "timestamp"},
    unique_key='order_id'
) }}

WITH orders_cleaned AS (
    SELECT 
        o.order_id, 
        o.customer_id, 
        COALESCE(c.customer_unique_id, 'Unknown') AS customer_unique_id,  
        o.order_status,  
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    FROM {{ source('raw', 'stg_orders_dataset') }} o
    LEFT JOIN {{ ref('dim_customers') }} c
        ON o.customer_id = c.customer_id  
)

SELECT * FROM orders_cleaned

{% if is_incremental() %}
WHERE order_purchase_timestamp > (SELECT MAX(order_purchase_timestamp) FROM {{ this }})
{% endif %}
