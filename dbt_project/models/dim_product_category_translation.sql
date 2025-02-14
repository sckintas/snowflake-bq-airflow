{{ config(
    materialized='incremental',
    cluster_by=['product_category_name'],
    unique_key='product_category_id'  
) }}

WITH unique_categories AS (
    -- Deduplicate product categories using QUALIFY
    SELECT 
        LOWER(TRIM(product_category_name)) AS product_category_name, 
        COALESCE(LOWER(TRIM(product_category_name_english)), 'Unknown') AS product_category_name_translated
    FROM {{ source('raw', 'stg_product_category_name_translation_dataset') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY LOWER(TRIM(product_category_name))
        ORDER BY product_category_name_english
    ) = 1

    UNION ALL

    -- ✅ Automatically add missing categories that were not in the source
    SELECT 
        'pc_gamer' AS product_category_name, 
        'PC Gamer' AS product_category_name_translated
    UNION ALL
    SELECT 
        'portateis_cozinha_e_preparadores_de_alimentos' AS product_category_name, 
        'Kitchen Food Processors' AS product_category_name_translated
)

SELECT 
    -- Generate a stable surrogate key as INT64
    CAST(FARM_FINGERPRINT(unique_categories.product_category_name) AS INT64) AS product_category_id,
    unique_categories.product_category_name, 
    unique_categories.product_category_name_translated, 
    CURRENT_TIMESTAMP() AS processed_at  
FROM unique_categories

{% if is_incremental() %}
LEFT JOIN {{ this }} existing
ON unique_categories.product_category_name = existing.product_category_name
WHERE existing.product_category_id IS NULL
{% endif %}
