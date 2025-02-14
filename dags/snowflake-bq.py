from airflow import DAG
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from google.cloud import bigquery
import pandas as pd
from datetime import timedelta

# Define connections
SNOWFLAKE_CONN_ID = "snowflake_conn_id"
BIGQUERY_CONN_ID = "bigquery_conn_id"
BQ_DATASET = "raw_ecommerce"

# ✅ Snowflake table names (without stg_ prefix)
SNOWFLAKE_TABLES = [
    "customers_dataset", "geolocation_dataset", "orders_dataset", "order_items_dataset", "order_payments_dataset",
    "order_reviews_dataset", "products_dataset", "sellers_dataset", "product_category_name_translation_dataset"
]

# ✅ BigQuery table names (with stg_ prefix)
BIGQUERY_TABLES = [f"stg_{table}" for table in SNOWFLAKE_TABLES]

default_args = {
    "owner": "airflow",
    "start_date": days_ago(1),
    "depends_on_past": False,
    "retries": 3,  # Increase the number of retries
    "retry_delay": timedelta(minutes=5),  # Add a delay between retries
}

def transfer_snowflake_to_bigquery(snowflake_table, bigquery_table, **kwargs):
    """
    Transfer data from Snowflake to BigQuery with correct data type conversion.
    """
    # Extract data from Snowflake
    snowflake_hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)
    snowflake_conn = snowflake_hook.get_conn()
    cursor = snowflake_conn.cursor()

    query = f"SELECT * FROM {snowflake_table}"
    cursor.execute(query)
    rows = cursor.fetchall()
    columns = [col[0] for col in cursor.description]

    # Convert to DataFrame
    df = pd.DataFrame(rows, columns=columns)

    # Convert Decimal columns to Float explicitly
    if 'GEOLOCATION_LAT' in df.columns and 'GEOLOCATION_LNG' in df.columns:
        df['GEOLOCATION_LAT'] = df['GEOLOCATION_LAT'].astype(float)
        df['GEOLOCATION_LNG'] = df['GEOLOCATION_LNG'].astype(float)

    # Load data into BigQuery
    bigquery_hook = BigQueryHook(gcp_conn_id=BIGQUERY_CONN_ID)
    client = bigquery_hook.get_client()

    table_id = f"{BQ_DATASET}.{bigquery_table}"
    job = client.load_table_from_dataframe(
        df, table_id, job_config=bigquery.LoadJobConfig(write_disposition="WRITE_TRUNCATE")
    )
    job.result()  # Wait for the job to complete

    print(f"✅ Data loaded into BigQuery table {table_id}")


# Create DAG
with DAG(
    "snowflake_to_bigquery_dbt",
    default_args=default_args,
    schedule_interval="@daily",
    catchup=False,
) as dag:

    # List to store transfer tasks
    transfer_tasks = []

    for snowflake_table, bigquery_table in zip(SNOWFLAKE_TABLES, BIGQUERY_TABLES):
        transfer_task = PythonOperator(
            task_id=f"transfer_{bigquery_table}",
            python_callable=transfer_snowflake_to_bigquery,
            op_kwargs={"snowflake_table": snowflake_table, "bigquery_table": bigquery_table},
            provide_context=True,
        )
        transfer_tasks.append(transfer_task)

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command="export PATH=$PATH:/home/airflow/.local/bin && export DBT_PROFILES_DIR=/home/airflow/.dbt && cd /opt/airflow/dbt_project && dbt run",
        dag=dag,
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command="export PATH=$PATH:/home/airflow/.local/bin && export DBT_PROFILES_DIR=/home/airflow/.dbt && cd /opt/airflow/dbt_project && dbt test",
        dag=dag,
    )





    # Define task dependencies
    transfer_tasks >> dbt_run >> dbt_test