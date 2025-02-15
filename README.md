# Airflow to BigQuery ETL Pipeline

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Technologies Used](#technologies-used)
- [Pipeline Overview](#pipeline-overview)
- [BigQuery Setup](#bigquery-setup)
- [DBT Transformation](#dbt-transformation)
- [Task Automation and Scheduling](#task-automation-and-scheduling)
- [Error Handling and Retries](#error-handling-and-retries)
- [CI/CD Workflow with GitHub Actions](#cicd-workflow-with-github-actions)
- [Installation](#installation)
- [Usage](#usage)
- [Results](#results)
- [Contributing](#contributing)
- [License](#license)

---

## **Introduction**

The **Airflow to BigQuery ETL Pipeline** is an automated system that transfers raw data from **Snowflake** into **Google BigQuery**, then uses **DBT (Data Build Tool)** to transform the data into a format ready for analysis. By leveraging **Apache Airflow** for task automation and scheduling, this pipeline ensures data is continually updated and transformed in a structured, scalable, and reliable manner. The end result is a pipeline that can help data analysts and engineers deliver high-quality data for downstream analytics.

---

## **Features**
- **Data Extraction:** Efficiently extracts raw data from **Snowflake** tables and loads it into **BigQuery**.
- **Data Transformation:** Uses **DBT** to transform the raw data into a cleansed and structured format.
- **Task Automation:** Airflow automates and schedules ETL tasks.
- **Error Handling:** Built-in retries and error handling to ensure robustness.
- **Data Quality:** The pipeline includes steps to validate data and ensure transformations are accurate.
- **CI/CD Workflow:** GitHub Actions automates **testing, validation, and deployment**.

---

## **Technologies Used**
- **Programming Language:** Python
- **Orchestration:** Apache Airflow
- **Cloud Provider:** Google Cloud (BigQuery)
- **Database:** Snowflake
- **Data Transformation:** DBT (Data Build Tool)
- **Task Scheduling:** Airflow
- **Infrastructure as Code:** Terraform
- **CI/CD Pipeline:** GitHub Actions
- **Version Control:** Git

---

## **Pipeline Overview**

### **1. Data Extraction from Snowflake**
The first stage of the pipeline extracts raw data from Snowflake tables, which represent various business functions such as customer data, orders, products, reviews, etc. This data is transferred into **BigQuery**'s staging tables for further processing.

Key Data Sources:
- **Customers**
- **Orders**
- **Order Items**
- **Products**
- **Sellers**
- **Geolocation**
- **Order Payments**
- **Order Reviews**
- **Product Category Translation**

Each of these Snowflake tables is transferred to BigQuery and stored in staging tables prefixed with **`stg_`** (e.g., `stg_customers_dataset`, `stg_orders_dataset`).

### **2. Data Loading to BigQuery**
The data from Snowflake is loaded into **BigQuery** using **Airflow** and **Google Cloud Integration**. This process is automated and occurs via Python operators within an **Airflow DAG**.

Staging tables in BigQuery are created dynamically using **Terraform** to ensure correct schema definitions, ensuring data types are compatible with downstream operations.

### **3. Data Transformation Using DBT**
Once the raw data is loaded into BigQuery, **DBT** is used to run a series of transformations on the staging tables. The transformations clean, enrich, and prepare the data for analysis.

Examples of transformations include:
- Aggregating raw transactional data into meaningful metrics.
- Joining multiple staging tables to create fact and dimension tables.
- Applying business logic to standardize and clean the data.

---

## **Task Automation and Scheduling**
**Apache Airflow** orchestrates and automates the entire ETL process. It schedules tasks and ensures that each task runs in the correct order. Task dependencies are defined, such as:
- **Data Transfer Task:** Transfer data from Snowflake to BigQuery staging tables.
- **DBT Run Task:** Execute DBT transformations after data loading.
- **DBT Test Task:** Validate transformed data with DBT tests.

Airflow’s scheduling ensures the ETL pipeline runs on a regular basis, keeping data in BigQuery fresh.

---

## **Error Handling and Retries**
The pipeline is designed with robust error handling. Each task in the Airflow DAG includes retry logic to handle temporary failures. Tasks will be retried up to three times with a 5-minute delay between retries, ensuring the pipeline is resilient to short-term issues.

---

## **CI/CD Workflow with GitHub Actions**
The pipeline includes a **CI/CD process** using **GitHub Actions** to automate testing, validation, and deployment.

### **1. CI/CD Pipeline Stages**
The CI/CD workflow includes the following stages:
- **Linting:** Runs `flake8` to check Python code quality.
- **DAG Import Tests:** Ensures all Airflow DAGs can be imported without errors.
- **Service Account Key Setup:** Restores the Google Cloud service account key securely.
- **DBT Setup:** Configures `profiles.yml` for BigQuery authentication.
- **DBT Dependency Installation:** Runs `dbt deps` to install required dbt packages.
- **DBT Tests:** Executes `dbt test` to validate the transformations.
- **Airflow Connection Check:** Verifies that the Airflow webserver is running.

### **2. GitHub Actions Workflow (`.github/workflows/airflow-ci.yml`)**
The CI/CD workflow is defined in `.github/workflows/airflow-ci.yml`:

```yaml
name: Airflow CI

on: [push, pull_request]

jobs:
  airflow-ci:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.9"

      - name: Install dependencies
        run: |
          pip install apache-airflow apache-airflow-providers-google apache-airflow-providers-snowflake flake8 dbt-bigquery

      - name: Lint DAGs
        run: |
          flake8 dags/ --max-line-length=120

      - name: Restore GCP Service Account Key
        env:
          GCP_SERVICE_ACCOUNT_KEY: ${{ secrets.GCP_SERVICE_ACCOUNT_KEY }}
        run: |
          export DBT_PROFILES_DIR=$HOME/.dbt
          mkdir -p $DBT_PROFILES_DIR
          echo $GCP_SERVICE_ACCOUNT_KEY | base64 --decode > $DBT_PROFILES_DIR/service-account.json

      - name: Install dbt Dependencies
        run: |
          cd $GITHUB_WORKSPACE/dbt_project
          dbt deps

      - name: Run dbt Tests
        run: |
          cd $GITHUB_WORKSPACE/dbt_project
          dbt test

      - name: Test Connection to Local Airflow
        run: |
          curl -I http://localhost:8080 || echo "❌ Airflow is not reachable"
