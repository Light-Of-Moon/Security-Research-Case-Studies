FROM python:3.12-alpine
WORKDIR /app
COPY receiver.py /app/receiver.py
USER 65532:65532
ENTRYPOINT ["python", "-u", "/app/receiver.py"]
