SELECT *
FROM {{ assert_unique_order_ids(ref('orders_fact')) }}
