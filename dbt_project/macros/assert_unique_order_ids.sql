{% macro assert_unique_order_ids(model) %}
    (
        WITH duplicate_orders AS (
            SELECT 
                order_id, COUNT(*) AS cnt
            FROM {{ model }}
            GROUP BY order_id
            HAVING COUNT(*) > 1
        )
        SELECT * FROM duplicate_orders
    )
{% endmacro %}
