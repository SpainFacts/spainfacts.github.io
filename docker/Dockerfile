FROM python:3.12-slim

WORKDIR /opt/spainfacts
ENV PYTHONPATH=/opt/spainfacts \
    DAGSTER_HOME=/opt/dagster/home \
    DBT_PROFILES_DIR=/opt/spainfacts/transform

RUN mkdir -p /opt/dagster/home

COPY orchestration/requirements.txt orchestration/requirements.txt
RUN pip install --no-cache-dir -r orchestration/requirements.txt

COPY ingestion/ ingestion/
COPY transform/ transform/
COPY orchestration/ orchestration/
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
