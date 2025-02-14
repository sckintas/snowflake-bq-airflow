SELECT * 
FROM {{ assert_missing_customers(ref('orders_fact'), ref('dim_customers')) }}
