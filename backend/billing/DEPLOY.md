# Deploying SelahBridgePro billing

This is NOT active yet. Nothing here fabricates a Stripe account, product,
or key — you need to do the Stripe-dashboard steps yourself since it's tied
to your real business/bank account. Everything else (code, service, nginx
route) is ready to go the moment real credentials exist.

## 0. Recommended: start in Stripe TEST mode

Do all of this once in Stripe's test mode first (toggle in the dashboard),
use a test card (`4242 4242 4242 4242`, any future date/CVC) to run a full
purchase through, confirm a key actually gets issued, THEN repeat the setup
in live mode. Test and live mode have separate API keys, products, and
webhook secrets — don't mix them.

## 1. Create the Stripe product + price

Dashboard → Product catalog → **Add product**:
- Name: `SelahBridgePro License`
- Pricing: **Recurring**, `$69.99 USD`, billed **yearly**
- Save, then copy the **Price ID** (`price_...`) — this goes in `.env` as
  `STRIPE_PRICE_ID`.

## 2. Create the beta-tester first-year discount

This is how "$29.95 first year, then $69.99/year" actually works: one
recurring price at the full $69.99, plus a coupon that knocks $40.04 off
**only the first invoice**. Every renewal after that bills the full amount
automatically — no custom scheduling code needed.

Dashboard → Product catalog → **Coupons** → **New**:
- Type: **Amount off** → `$40.04` → **Once** (not "Forever" or "Multi-month")
- Currency: USD

Then → **Promotion codes** → **New**, attach it to that coupon, set the
customer-facing code to something like `BETAYEAR1`. Give this code only to
actual beta/early testers — anyone without it pays the full $69.99 from
their very first invoice, which is the intended behavior for later Beta
2.0.2 / Beta 3 arrivals who weren't part of the original beta cohort.

## 3. Set up the webhook

Dashboard → Developers → Webhooks → **Add endpoint**:
- URL: `https://selahos.io/api/billing/webhook`
- Events to send: `checkout.session.completed`
- After creating it, reveal and copy the **Signing secret** (`whsec_...`)
  — this goes in `.env` as `STRIPE_WEBHOOK_SECRET`.

## 4. Get your API key

Dashboard → Developers → API keys → copy the **Secret key** (`sk_...`) —
goes in `.env` as `STRIPE_SECRET_KEY`. Never put this in the website repo,
in frontend code, or anywhere public.

## 5. Deploy the code to web-core

Claude Code can `rsync` `app.py`, `requirements.txt`, and
`selah-billing.service` to `web-core:~/apps/selah-billing/` (same pattern as
the contribute-form backend, outside `/var/www/selahos` on purpose). You
still need to do the parts below by hand (sudo + real secrets):

```bash
cd ~/apps/selah-billing
cp .env.example .env
nano .env   # fill in the 3 real Stripe values from steps 1-4 above

python3 -m venv venv
./venv/bin/pip install -r requirements.txt

sudo cp selah-billing.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now selah-billing.service
sudo systemctl status selah-billing.service --no-pager
```

## 6. Add the nginx routes

Edit `/etc/nginx/sites-enabled/selahOS` and add inside the `server {}` block:

```nginx
location /api/billing/ {
    proxy_pass http://127.0.0.1:5151/api/billing/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
```

## 7. Test end-to-end (in Stripe TEST mode first)

1. Visit `https://selahos.io/selahbridgepro/`
2. Enter a fake-but-valid-format 32-hex machine ID and your email
3. Optionally enter promo code `BETAYEAR1`
4. Pay with the Stripe test card `4242 4242 4242 4242`
5. Confirm you land on the success page and a key appears within a few
   seconds (it polls `/api/billing/session/<id>` until the webhook has run)
6. Check `~/apps/selah-billing/billing.db` — a `sqlite3`/Python one-liner
   works the same way as the contribute-form database (see that
   `DEPLOY.md` for the exact commands)

Only repeat all of steps 1-6 in **live mode** once the test run works.

## Known limitation — flagged, not fixed here

The key this issues has **no expiration** — the existing keygen service
(`/keygen/app.py`) derives a key purely from `machine_id + secret`, so it's
valid forever once issued. This billing system correctly charges the
customer every year, but nothing currently stops someone from just not
renewing and keeping a working key indefinitely. Making the yearly renewal
actually enforce anything requires the SelahBridgePro **client itself**
(`selahpro`'s license check, in the OS-side repo) to validate an expiry
date — that's a different repo and wasn't touched here. Worth raising with
the OS-side session before taking real payments at scale.
