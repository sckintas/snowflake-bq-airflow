# Use an Airflow image with Python 3.9
FROM apache/airflow:2.7.0-python3.9

# Set environment variables
ENV AIRFLOW_HOME=/opt/airflow
ENV AIRFLOW__CORE__LOAD_EXAMPLES=False

# Set working directory
WORKDIR ${AIRFLOW_HOME}

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy DAGs and plugins
COPY dags/ ${AIRFLOW_HOME}/dags/
COPY plugins/ ${AIRFLOW_HOME}/plugins/

# Default command
CMD ["airflow", "webserver"]
