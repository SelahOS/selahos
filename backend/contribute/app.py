#!/usr/bin/env python3
"""
SelahOS Contribute — backend for the /contribute form on selahos.io.

Collects people who want to contribute to SelahOS development (code,
testing, docs, design, etc.) into a local SQLite database so they can be
reviewed later — a lightweight record of interested contributors and
potential future hires.

Deliberately kept outside the nginx-served web root (/var/www/selahos) —
this file and the database it creates should never be reachable over
HTTP. See ../../DEPLOY.md for setup instructions.
"""
import re
import sqlite3
import time
from pathlib import Path

from flask import Flask, jsonify, request

APP_DIR = Path(__file__).resolve().parent
DB_PATH = APP_DIR / "contributions.db"

app = Flask(__name__)

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
AREAS = {
    "development",
    "testing",
    "documentation",
    "design",
    "hardware",
    "audio-music",
    "community",
    "other",
}


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS contributions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at INTEGER NOT NULL,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            area TEXT NOT NULL,
            link TEXT,
            message TEXT NOT NULL
        )
        """
    )
    return conn


@app.post("/api/contribute")
def contribute():
    data = request.get_json(silent=True) or request.form

    # Honeypot field: real visitors never fill this in (it's hidden via
    # CSS on the form), bots often do. Pretend success and drop it.
    if (data.get("website") or "").strip():
        return jsonify({"ok": True}), 200

    name = (data.get("name") or "").strip()[:200]
    email = (data.get("email") or "").strip()[:200]
    area = (data.get("area") or "").strip().lower()
    link = (data.get("link") or "").strip()[:500]
    message = (data.get("message") or "").strip()[:5000]
    consent = data.get("consent")

    if not name or not email or not message:
        return jsonify({"ok": False, "error": "Name, email, and message are required."}), 400
    if not EMAIL_RE.match(email):
        return jsonify({"ok": False, "error": "Please provide a valid email address."}), 400
    if not consent:
        return jsonify({"ok": False, "error": "Please confirm you're okay with us keeping your info on file."}), 400
    if area not in AREAS:
        area = "other"

    conn = get_db()
    conn.execute(
        "INSERT INTO contributions (created_at, name, email, area, link, message) VALUES (?, ?, ?, ?, ?, ?)",
        (int(time.time()), name, email, area, link, message),
    )
    conn.commit()
    conn.close()

    return jsonify({"ok": True}), 200


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5150)
