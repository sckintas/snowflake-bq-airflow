provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "raw_ecommerce" {
  dataset_id    = "raw_ecommerce"
  friendly_name = "Raw Ecommerce Dataset"
  description   = "Dataset for storing raw data before dbt transformation"
  location      = "US"
}

# ✅ Define tables and their schemas
locals {
  tables = {
    stg_customers_dataset = [
      { "name": "customer_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "customer_unique_id", "type": "STRING", "mode": "NULLABLE" },
      { "name": "customer_zip_code_prefix", "type": "STRING", "mode": "NULLABLE" },
      { "name": "customer_city", "type": "STRING", "mode": "NULLABLE" },
      { "name": "customer_state", "type": "STRING", "mode": "NULLABLE" }
    ],
    stg_orders_dataset = [
      { "name": "order_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "customer_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "order_status", "type": "STRING", "mode": "NULLABLE" },
      { "name": "order_purchase_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE" }
    ],
    stg_order_items_dataset = [
      { "name": "order_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "order_item_id", "type": "INTEGER", "mode": "REQUIRED" },
      { "name": "product_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "seller_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "price", "type": "FLOAT", "mode": "NULLABLE" },
      { "name": "freight_value", "type": "FLOAT", "mode": "NULLABLE" }
    ],
    stg_products_dataset = [
      { "name": "product_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "product_category_name", "type": "STRING", "mode": "NULLABLE" },
      { "name": "product_weight_g", "type": "FLOAT", "mode": "NULLABLE" }
    ],
    stg_sellers_dataset = [
      { "name": "seller_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "seller_zip_code_prefix", "type": "STRING", "mode": "NULLABLE" },
      { "name": "seller_city", "type": "STRING", "mode": "NULLABLE" }
    ],
    stg_geolocation_dataset = [
      { "name": "geolocation_zip_code_prefix", "type": "STRING", "mode": "REQUIRED" },
      { "name": "geolocation_lat", "type": "FLOAT", "mode": "NULLABLE" },
      { "name": "geolocation_lng", "type": "FLOAT", "mode": "NULLABLE" },
      { "name": "geolocation_city", "type": "STRING", "mode": "NULLABLE" },
      { "name": "geolocation_state", "type": "STRING", "mode": "NULLABLE" }
    ],
    stg_order_payments_dataset = [
      { "name": "order_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "payment_type", "type": "STRING", "mode": "NULLABLE" },
      { "name": "payment_value", "type": "FLOAT", "mode": "NULLABLE" }
    ],
    stg_order_reviews_dataset = [
      { "name": "review_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "order_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "review_score", "type": "INTEGER", "mode": "NULLABLE" },
      { "name": "review_creation_date", "type": "TIMESTAMP", "mode": "NULLABLE" }
    ],
    stg_product_category_name_translation_dataset = [
      { "name": "product_category_name", "type": "STRING", "mode": "REQUIRED" },
      { "name": "product_category_name_english", "type": "STRING", "mode": "NULLABLE" }
    ]
  }
}

# ✅ Dynamically create all tables
resource "google_bigquery_table" "staging_tables" {
  for_each  = local.tables
  dataset_id = google_bigquery_dataset.raw_ecommerce.dataset_id
  table_id   = each.key

  schema = jsonencode(each.value)

  labels = {
    environment = "staging"
    source      = "snowflake"
  }
}
