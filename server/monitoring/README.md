# Monitoring — Prometheus + Grafana

A self-contained monitoring stack run via Docker Compose:

- **Prometheus** (`:9090`) — scrapes metrics targets.
- **Grafana** (`:3000`) — visualizes them, with the Prometheus datasource and a starter dashboard auto-provisioned.

## Structure

```
monitoring/
├── docker-compose.yaml
├── .env.example                       # Grafana admin creds (copy to .env)
├── prometheus/
│   └── prometheus.yml                 # Scrape config
└── grafana/
    ├── provisioning/
    │   ├── datasources/datasource.yml # Auto-wires Prometheus datasource
    │   └── dashboards/dashboards.yml  # Auto-loads dashboards from disk
    └── dashboards/
        └── prometheus-overview.json   # Starter dashboard
```

## Run

```bash
cd server/monitoring

# (optional) override Grafana admin credentials
cp .env.example .env

docker compose up -d
```

Then open:

- Prometheus → http://localhost:9090 (check **Status → Targets**)
- Grafana → http://localhost:3000 (login `admin` / `admin` unless overridden)
  - Dashboard: **Book-App Monitoring Overview** (auto-provisioned)

Stop the stack:

```bash
docker compose down          # keep data
docker compose down -v       # also remove volumes (prometheus/grafana data)
```

## Scraping the backend app

`prometheus/prometheus.yml` includes a `book-app-backend` job pointing at
`host.docker.internal:5001`. To make it report `UP`, the Flask backend needs a
`/metrics` endpoint. Quickest way:

1. Add to `backend/requirements.txt`:
   ```
   prometheus-flask-exporter
   ```
2. In `backend/app.py`, after `app = Flask(__name__)`:
   ```python
   from prometheus_flask_exporter import PrometheusMetrics
   metrics = PrometheusMetrics(app)
   ```
3. Restart the backend — Prometheus will start collecting request rate,
   latency, and status-code metrics automatically.

Until then, the `prometheus` self-scrape job still works, so Grafana shows
live data out of the box.
