{{ config(
    materialized='incremental',
    cluster_by=['product_id'],
    unique_key='product_id'
) }}

WITH product_data AS (
    SELECT 
        p.product_id, 
        COALESCE(c.product_category_id, -1) AS product_category_id,  -- ✅ Default category ID for NULLs
        COALESCE(p.product_category_name, 'Unknown') AS product_category_name,  -- ✅ Default category name for NULLs
        COALESCE(p.product_name_lenght, 0) AS product_name_lenght,
        COALESCE(p.product_description_lenght, 0) AS product_description_lenght,
        COALESCE(p.product_photos_qty, 0) AS product_photos_qty,
        COALESCE(p.product_weight_g, 0) AS product_weight_g,
        COALESCE(p.product_length_cm, 0) AS product_length_cm,
        COALESCE(p.product_height_cm, 0) AS product_height_cm,
        COALESCE(p.product_width_cm, 0) AS product_width_cm
    FROM {{ source('raw', 'stg_products_dataset') }} p
    LEFT JOIN {{ ref('dim_product_category_translation') }} c
        ON LOWER(TRIM(p.product_category_name)) = LOWER(TRIM(c.product_category_name))
)

SELECT *
FROM product_data
{% if is_incremental() %}
WHERE product_id NOT IN (SELECT product_id FROM {{ this }})
{% endif %}
