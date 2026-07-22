"""
GuardZen Secure CI/CD Pipeline — demo target application
Deliberately contains a few common vulnerabilities so the pipeline's
SAST / container / secrets scanning stages have something real to catch.
DO NOT deploy this app anywhere public — it is a controlled test target only.
"""

import sqlite3
from flask import Flask, request, jsonify

app = Flask(__name__)

# --- VULN 1: hardcoded secret (Gitleaks / Trivy secret scanning should flag this) ---
API_SECRET_KEY = "guardzen_demo_secret_key_1234567890abcdef"  # noqa: placeholder, intentional test fixture

DB_PATH = "users.db"


def get_db():
    conn = sqlite3.connect(DB_PATH)
    return conn


@app.route("/")
def index():
    return jsonify({"service": "GuardZen demo API", "status": "ok"})


@app.route("/user")
def get_user():
    """
    VULN 2: SQL injection — user input concatenated directly into query.
    SAST tools (SonarQube/Semgrep) should flag this as a classic SQLi sink.
    """
    username = request.args.get("username", "")
    conn = get_db()
    cur = conn.cursor()
    query = "SELECT id, username, email FROM users WHERE username = '" + username + "'"
    cur.execute(query)
    row = cur.fetchone()
    conn.close()
    if row:
        return jsonify({"id": row[0], "username": row[1], "email": row[2]})
    return jsonify({"error": "not found"}), 404


@app.route("/debug")
def debug_info():
    """
    VULN 3: debug endpoint leaking internal config — flagged as
    information disclosure by SAST rules.
    """
    return jsonify({"secret_key_prefix": API_SECRET_KEY[:8], "db_path": DB_PATH})


if __name__ == "__main__":
    # VULN 4: debug=True in what looks like a runnable entrypoint
    app.run(host="0.0.0.0", port=5000, debug=True)
