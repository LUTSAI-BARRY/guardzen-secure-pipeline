# Intentionally pinned to an older tag so the container-scanning stage
# (Trivy) has real, known CVEs to detect. Swap to a current slim/distroless
# image once you've captured your "before" scan report for the writeup.
FROM python:3.9-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 5000

# VULN: running as root (no USER directive) — Trivy/Docker best-practice
# checks will flag this; fix it in your "after" pass.
CMD ["python", "app.py"]
