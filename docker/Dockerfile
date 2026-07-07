FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /opt/spainfacts
ENV PYTHONPATH=/opt/spainfacts \
    DAGSTER_HOME=/opt/dagster/home \
    DBT_PROFILES_DIR=/opt/spainfacts/transform

RUN mkdir -p /opt/dagster/home

COPY orchestration/requirements.txt orchestration/requirements.txt
RUN uv pip install --system --no-cache -r orchestration/requirements.txt

COPY ingestion/ ingestion/
COPY transform/ transform/
COPY orchestration/ orchestration/
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
