# 🚀 Skillture — Deployment Guide

> Deploy to **skillture.club** with automatic HTTPS and subdomain routing.

| Domain | Purpose |
|--------|---------|
| `skillture.club` | Homepage / Landing page |
| `api.skillture.club` | Admin Dashboard + API + Public Forms |

---

## Architecture

```
                    ┌──────────────────────┐
  Internet ──────►  │   Caddy (port 80/443)│
                    │   Auto SSL via        │
                    │   Let's Encrypt       │
                    └───────┬──────┬────────┘
                            │      │
            ┌───────────────┘      └───────────────┐
            ▼                                      ▼
   api.skillture.club                    skillture.club
   ┌─────────────────┐                 ┌──────────────────┐
   │  Go App (:8080) │                 │  Static Homepage  │
   │  React Admin +  │                 │  (homepage/)      │
   │  API + Forms    │                 └──────────────────┘
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │ PostgreSQL 16   │
   │ + pgvector      │
   │ (pgdata volume) │
   └─────────────────┘
```

---

## Prerequisites

- A server (DigitalOcean Droplet, Google Compute Engine, etc.)
- **1 GB RAM** minimum, **10 GB disk**
- Domain `skillture.club` DNS pointing to your server:
  ```
  A record:  skillture.club       →  YOUR_SERVER_IP
  A record:  api.skillture.club   →  YOUR_SERVER_IP
  ```

---

## Step-by-Step Deployment

### 1. Prepare the Server

```bash
# SSH into your server
ssh root@YOUR_SERVER_IP

# Install Docker (if not installed)
curl -fsSL https://get.docker.com | sh
```

### 2. Clone & Configure

```bash
git clone <your-repo-url>
cd Skillture_Form

# Create environment file
cp .env.example .env
nano .env
# ⚠️ Set a STRONG password for POSTGRES_PASSWORD
```

### 3. Set Up DNS

Go to your domain registrar and add two **A records**:

| Type | Name | Value |
|------|------|-------|
| A | `@` (or `skillture.club`) | Your server IP |
| A | `api` | Your server IP |

> Wait a few minutes for DNS to propagate.

### 4. Deploy

```bash
# Build and start everything
docker compose up -d --build

# Check status
docker compose ps
```

That's it! Caddy automatically obtains SSL certificates from Let's Encrypt.

- **Dashboard**: https://api.skillture.club/admin/dashboard
- **Homepage**: https://skillture.club

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_DB` | `skillture_form` | Database name |
| `POSTGRES_USER` | `skillture` | Database username |
| `POSTGRES_PASSWORD` | ⚠️ **must change** | Database password |
| `SERVER_PORT` | `8080` | Internal app port (don't change) |

---

## Data Persistence

All data is in Docker named volumes:

| Volume | Contains | Survives `docker compose down`? |
|--------|----------|------|
| `pgdata` | Database data | ✅ Yes |
| `caddy_data` | SSL certificates | ✅ Yes |
| `caddy_config` | Caddy config cache | ✅ Yes |

> ⚠️ Only `docker compose down -v` deletes volumes (irreversible).

### Backup Database

```bash
# Create backup
docker compose exec db pg_dump -U skillture skillture_form > backup_$(date +%Y%m%d).sql

# Restore
cat backup.sql | docker compose exec -T db psql -U skillture skillture_form
```

---

## Updating the App

```bash
# Pull latest code
git pull origin main

# Rebuild and restart (DB data is preserved)
docker compose up -d --build
```

---

## Updating the Homepage

Edit files in the `homepage/` directory. Changes are mounted as a volume — just restart Caddy:

```bash
docker compose restart caddy
```

---

## Useful Commands

```bash
# View logs
docker compose logs -f app      # App logs
docker compose logs -f db       # Database logs
docker compose logs -f caddy    # Caddy/SSL logs

# Restart everything
docker compose restart

# Stop (data preserved)
docker compose down

# Enter database
docker compose exec db psql -U skillture skillture_form

# Check SSL certificate status
docker compose exec caddy caddy list-certificates
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| SSL certificate error | Ensure DNS A records point to your server, wait for propagation |
| "Connection refused" | Check `docker compose ps` — all containers should be "Up" |
| App can't connect to DB | Check DB health: `docker compose logs db` |
| Homepage not showing | Check `homepage/index.html` exists |
| 502 Bad Gateway | App is starting — wait 10 seconds and refresh |
| Caddy rate limit | Let's Encrypt has limits; don't recreate containers too often |
