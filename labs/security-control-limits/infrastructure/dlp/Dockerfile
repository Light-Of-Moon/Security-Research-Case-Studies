FROM python:3.12-alpine
WORKDIR /app
COPY gateway.py /app/gateway.py
USER 65532:65532
ENTRYPOINT ["python", "-u", "/app/gateway.py"]
