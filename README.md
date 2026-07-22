# GuardZen Secure CI/CD Pipeline

**Practicing what we preach.** Before GuardZen recommends a DevSecOps posture
to SME clients, we run our own deployment pipeline through the same gates:
static analysis, secrets detection, container scanning, and infrastructure-
as-code scanning — all enforced automatically before anything reaches
production.

## Architecture

```
 commit/PR
     │
     ▼
 ┌─────────────────┐
 │ Secrets Scan     │  Gitleaks — blocks hardcoded credentials
 └────────┬─────────┘
          ▼
 ┌─────────────────┐
 │ SAST             │  Semgrep — flags SQLi, debug leaks, unsafe patterns
 └────────┬─────────┘
          ▼
 ┌─────────────────┐        ┌─────────────────┐
 │ Container Scan   │        │ IaC Scan         │
 │ Trivy            │        │ tfsec            │
 └────────┬─────────┘        └────────┬─────────┘
          └───────────┬───────────────┘
                       ▼
              ┌─────────────────┐
              │  Deploy Gate     │  fails the build on
              │  (fail-closed)   │  CRITICAL/HIGH findings
              └─────────────────┘
```

## What's intentionally broken here (for the demo)

| Component | Issue | Caught by |
|---|---|---|
| `app/app.py` | Hardcoded API key | Gitleaks |
| `app/app.py` | SQL injection in `/user` | Semgrep |
| `app/app.py` | Debug info leak, `debug=True` | Semgrep |
| `Dockerfile` | Outdated base image, runs as root | Trivy |
| `terraform/main.tf` | Public S3 bucket, unrestricted SSH ingress | tfsec |

Run the pipeline once against this "before" state, capture the failing
report as evidence, then fix each issue and re-run for the "after" report.
That before/after pair is the centerpiece of your writeup.

## Sample GuardZen Security Report (template)

```
GuardZen Security Report — Pipeline Run #<sha>
Date: <date>
Repo: guardzen-secure-pipeline

Summary: 2 CRITICAL, 3 HIGH findings — build BLOCKED

Findings:
1. [CRITICAL] Hardcoded secret detected in app/app.py:12 (Gitleaks)
2. [HIGH] SQL injection sink in app/app.py:32 (Semgrep, CWE-89)
3. [HIGH] Base image python:3.9-slim has N known CVEs (Trivy)
4. [CRITICAL] S3 bucket guardzen-demo-reports-bucket is public-read-write (tfsec)
5. [HIGH] Security group allows 0.0.0.0/0 on port 22 (tfsec)

Recommendation: Remediate before deploy. Re-run pipeline to confirm.
```

## Fix checklist (for your "after" pass)

- [ ] Move the API key to GitHub Actions secrets / environment variables
- [ ] Parameterize the SQL query (use `?` placeholders, never string concat)
- [ ] Remove the `/debug` endpoint or gate it behind auth
- [ ] Set `debug=False`, bump base image to a current `python:3.12-slim`
- [ ] Add a non-root `USER` directive to the Dockerfile
- [ ] Change the S3 ACL to private, enable default encryption
- [ ] Restrict the security group ingress to a known IP range

## Why this matters for GuardZen clients

This same pipeline pattern is the basis for a **Secure Pipeline Audit &
Hardening** offering: point it at a client's repo, run the four gates,
hand them a report identical in shape to the one above, and price the
remediation work separately.
