# model-downloader/Dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY run.sh /app/
RUN apt-get update && apt-get install -y wget curl && \
    chmod +x /app/run.sh
CMD ["/app/run.sh"]
