{{
    config(
        materialized='incremental',
        partition_by={
            "field": "shipping_limit_date",
            "data_type": "date"
        },
        cluster_by=["order_id", "product_id", "seller_id"],
        unique_key="order_item_id"
    )
}}

WITH base_order_items AS (
    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        DATE(shipping_limit_date) AS shipping_limit_date,  -- Ensure DATE type for partitioning
        price,
        freight_value,
        ROW_NUMBER() OVER (PARTITION BY order_id, order_item_id ORDER BY shipping_limit_date DESC) AS row_num
    FROM {{ source('raw', 'stg_order_items_dataset') }}
)

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM base_order_items
WHERE row_num = 1  -- Deduplicate records by keeping the latest entry

{% if is_incremental() %}
    AND shipping_limit_date > (SELECT MAX(shipping_limit_date) FROM {{ this }})  -- Ensure only new data is added
{% endif %}