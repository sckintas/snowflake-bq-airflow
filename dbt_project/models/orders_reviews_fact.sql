{{ config(
    materialized='incremental',
    partition_by={
        "field": "review_creation_date",
        "data_type": "date"
    }, 
    cluster_by=["order_id"],
    unique_key="review_id"
) }}

WITH base_reviews AS (
    SELECT
        review_id,
        order_id,
        review_score,
        DATE(review_creation_date) AS review_creation_date,  -- ✅ Ensuring DATE type for partitioning
        review_answer_timestamp,
        ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_creation_date DESC) AS row_num
    FROM {{ source('raw', 'stg_order_reviews_dataset') }}
)

SELECT
    review_id,
    order_id,
    review_score,
    review_creation_date,
    review_answer_timestamp
FROM base_reviews
WHERE row_num = 1  -- ✅ Deduplicate reviews by selecting the latest one

{% if is_incremental() %}
AND review_id NOT IN (SELECT review_id FROM {{ this }})  -- ✅ Fixing subquery issue
{% endif %}