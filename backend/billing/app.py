#!/usr/bin/env python3
"""
SelahBridgePro billing — Stripe Checkout + webhook that issues a license
key after real payment.

Replaces the old fully-public /license flow (closed 2026-09-12 for having
zero authentication) with: customer enters their machine ID -> pays via
Stripe Checkout -> webhook verifies the payment -> we call the EXISTING
keygen service internally (http://127.0.0.1:5050/license, not the public
internet) to get a real key -> store it + let the success page fetch it.

Deliberately kept outside /var/www/selahos, same lesson as the contribute
backend and the keygen exposure incident. See DEPLOY.md for setup.

REQUIRES real Stripe configuration before any of this works — see the
"Required setup" section in DEPLOY.md. Nothing here fabricates or assumes
a Stripe account, product, or key exists.
"""
import os
import re
import sqlite3
import time
from pathlib import Path

import requests
import stripe
from flask import Flask, jsonify, request

APP_DIR = Path(__file__).resolve().parent
DB_PATH = APP_DIR / "billing.db"

STRIPE_SECRET_KEY = os.environ.get("STRIPE_SECRET_KEY", "")
STRIPE_WEBHOOK_SECRET = os.environ.get("STRIPE_WEBHOOK_SECRET", "")
STRIPE_PRICE_ID = os.environ.get("STRIPE_PRICE_ID", "")  # the $69.99/year recurring Price
SITE_URL = os.environ.get("SITE_URL", "https://selahos.io")
KEYGEN_INTERNAL_URL = os.environ.get("KEYGEN_INTERNAL_URL", "http://127.0.0.1:5050/license")

stripe.api_key = STRIPE_SECRET_KEY

MACHINE_ID_RE = re.compile(r"^[0-9a-f]{32}$")
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

app = Flask(__name__)


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at INTEGER NOT NULL,
            stripe_session_id TEXT UNIQUE NOT NULL,
            stripe_subscription_id TEXT,
            machine_id TEXT NOT NULL,
            email TEXT NOT NULL,
            amount_total INTEGER,
            currency TEXT,
            license_key TEXT,
            status TEXT NOT NULL DEFAULT 'pending'
        )
        """
    )
    return conn


@app.post("/api/billing/checkout")
def create_checkout():
    """Start a Stripe Checkout session for a SelahBridgePro subscription."""
    if not STRIPE_SECRET_KEY or not STRIPE_PRICE_ID:
        return jsonify({"ok": False, "error": "Billing is not configured yet."}), 503

    data = request.get_json(silent=True) or {}
    machine_id = (data.get("machine_id") or "").strip().lower()
    email = (data.get("email") or "").strip()
    promo_code = (data.get("promo_code") or "").strip()

    if not MACHINE_ID_RE.match(machine_id):
        return jsonify({"ok": False, "error": "Invalid Machine ID. Run: selahpro --machine-id"}), 400
    if not EMAIL_RE.match(email):
        return jsonify({"ok": False, "error": "Please provide a valid email address."}), 400

    session_params = {
        "mode": "subscription",
        "line_items": [{"price": STRIPE_PRICE_ID, "quantity": 1}],
        "client_reference_id": machine_id,
        "customer_email": email,
        "success_url": f"{SITE_URL}/selahbridgepro/success.html?session_id={{CHECKOUT_SESSION_ID}}",
        "cancel_url": f"{SITE_URL}/selahbridgepro/",
        "allow_promotion_codes": True,
    }

    # A specific promo code (e.g. the beta-tester first-year discount) can
    # also be applied server-side instead of relying on the customer typing
    # it in at Stripe's checkout page.
    if promo_code:
        try:
            promos = stripe.PromotionCode.list(code=promo_code, active=True, limit=1)
            if promos.data:
                session_params["discounts"] = [{"promotion_code": promos.data[0].id}]
                del session_params["allow_promotion_codes"]
        except stripe.error.StripeError:
            pass  # fall back to letting the customer enter it at checkout

    try:
        checkout_session = stripe.checkout.Session.create(**session_params)
    except stripe.error.StripeError as e:
        return jsonify({"ok": False, "error": str(e)}), 502

    conn = get_db()
    conn.execute(
        "INSERT INTO orders (created_at, stripe_session_id, machine_id, email, status) VALUES (?, ?, ?, ?, 'pending')",
        (int(time.time()), checkout_session.id, machine_id, email),
    )
    conn.commit()
    conn.close()

    return jsonify({"ok": True, "checkout_url": checkout_session.url})


@app.post("/api/billing/webhook")
def stripe_webhook():
    """Stripe calls this after payment events. Verifies the signature."""
    payload = request.data
    sig_header = request.headers.get("Stripe-Signature", "")

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, STRIPE_WEBHOOK_SECRET)
    except (ValueError, stripe.error.SignatureVerificationError):
        return jsonify({"error": "Invalid signature"}), 400

    if event["type"] == "checkout.session.completed":
        session = event["data"]["object"]
        _issue_key_for_session(session)

    return jsonify({"received": True}), 200


def _issue_key_for_session(session):
    conn = get_db()
    row = conn.execute(
        "SELECT machine_id, license_key FROM orders WHERE stripe_session_id = ?",
        (session["id"],),
    ).fetchone()

    if row is None or row[1]:
        conn.close()
        return  # unknown session, or already issued (webhook can retry/duplicate)

    machine_id = row[0]

    try:
        resp = requests.post(KEYGEN_INTERNAL_URL, json={"machine_id": machine_id}, timeout=10)
        resp.raise_for_status()
        key = resp.json()["key"]
    except Exception:
        key = None  # leave status as 'paid' without a key; needs manual follow-up

    conn.execute(
        """
        UPDATE orders
        SET status = ?, license_key = ?, stripe_subscription_id = ?, amount_total = ?, currency = ?
        WHERE stripe_session_id = ?
        """,
        (
            "issued" if key else "paid_key_pending",
            key,
            session.get("subscription"),
            session.get("amount_total"),
            session.get("currency"),
            session["id"],
        ),
    )
    conn.commit()
    conn.close()


@app.get("/api/billing/session/<session_id>")
def check_session(session_id):
    """Polled by the success page until the webhook has issued a key."""
    conn = get_db()
    row = conn.execute(
        "SELECT status, license_key, machine_id FROM orders WHERE stripe_session_id = ?",
        (session_id,),
    ).fetchone()
    conn.close()

    if row is None:
        return jsonify({"ok": False, "error": "Unknown session"}), 404

    status, license_key, machine_id = row
    return jsonify({
        "ok": True,
        "status": status,
        "license_key": license_key,
        "machine_id": machine_id,
    })


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5151)
