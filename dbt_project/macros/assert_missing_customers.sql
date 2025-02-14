{% macro assert_missing_customers(orders_model, customers_model) %}
(
    SELECT order_id
    FROM {{ orders_model }}
    WHERE customer_id NOT IN (SELECT customer_id FROM {{ customers_model }})
) AS missing_customers
{% endmacro %}
