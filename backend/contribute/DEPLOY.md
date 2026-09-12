# Deploying the Contribute form backend

This backend is deliberately kept **outside** `/var/www/selahos` (the
nginx web root) — it should never be directly reachable over HTTP, only
through the `/api/contribute` proxy path. This is the same fix we just
applied for the keygen app's exposure.

These files get synced to `web-core:~/apps/selah-contribute/` by Claude
Code (via `rsync`, not committed anywhere web-servable). The steps below
need to be run by hand on `web-core`, since they require `sudo` and
Claude Code's own safety layer blocks it from running privileged/remote
setup commands itself.

## 1. One-time setup (after the files are synced to `~/apps/selah-contribute/`)

```bash
cd ~/apps/selah-contribute
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
```

## 2. Install the systemd service

```bash
sudo cp ~/apps/selah-contribute/selah-contribute.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now selah-contribute.service
sudo systemctl status selah-contribute.service --no-pager
```

## 3. Add the nginx proxy route

Edit `/etc/nginx/sites-enabled/selahOS` and add this inside the existing
`server { ... }` block (anywhere alongside the other `location` blocks):

```nginx
location = /api/contribute {
    proxy_pass http://127.0.0.1:5150/api/contribute;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

Then:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

## 4. Verify

```bash
curl -s -X POST https://selahos.io/api/contribute \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test","email":"test@example.com","area":"development","message":"test submission","consent":true}'
```

Should return `{"ok":true}`. Then confirm it landed:

```bash
sqlite3 ~/apps/selah-contribute/contributions.db "SELECT id, name, email, area, message FROM contributions ORDER BY id DESC LIMIT 1;"
```

Delete that test row once confirmed:

```bash
sqlite3 ~/apps/selah-contribute/contributions.db "DELETE FROM contributions WHERE email='test@example.com';"
```

## Reviewing submissions later

No admin UI was built on purpose — one more authenticated web endpoint
is one more thing that can leak. The `sqlite3` CLI isn't installed on
`web-core` by default; either install it (`sudo apt install sqlite3`)
and use the commands below, or use the venv's Python (already present,
no install needed) via the one-liner further down.

**Option A — install the CLI once:**

```bash
sudo apt install sqlite3

sqlite3 ~/apps/selah-contribute/contributions.db \
  "SELECT datetime(created_at, 'unixepoch'), name, email, area, link, message FROM contributions ORDER BY created_at DESC;"

# Export to CSV:
sqlite3 -header -csv ~/apps/selah-contribute/contributions.db \
  "SELECT datetime(created_at, 'unixepoch') AS submitted, name, email, area, link, message FROM contributions ORDER BY created_at DESC;" \
  > ~/contributions-export.csv
```

**Option B — no install, using the venv's Python:**

```bash
~/apps/selah-contribute/venv/bin/python3 -c "
import sqlite3
conn = sqlite3.connect('/home/dane/apps/selah-contribute/contributions.db')
for row in conn.execute('SELECT datetime(created_at, \"unixepoch\"), name, email, area, link, message FROM contributions ORDER BY created_at DESC'):
    print(row)
"
```

## Updating the app later

Claude Code can `rsync` an updated `app.py` to
`web-core:~/apps/selah-contribute/app.py` directly (no sudo needed, this
path is entirely `dane`-owned). After syncing a code change:

```bash
sudo systemctl restart selah-contribute.service
```
