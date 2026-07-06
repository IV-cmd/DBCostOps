#!/bin/bash
# DBCostOps - Start all services in dependency order

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE="docker compose -f $PROJECT_DIR/docker-compose.yml"

log()  { echo -e "${BLUE}[$(date +%T)]${NC} $*"; }
ok()   { echo -e "${GREEN}[$(date +%T)] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +%T)] ⚠${NC} $*"; }
fail() { echo -e "${RED}[$(date +%T)] ✗${NC} $*"; exit 1; }

wait_for_container() {
  local name=$1
  local max=${2:-120}
  local elapsed=0
  log "Waiting for $name..."
  while [ $elapsed -lt $max ]; do
    health=$(docker inspect --format='{{.State.Health.Status}}' "$name" 2>/dev/null || echo "missing")
    state=$(docker inspect --format='{{.State.Status}}'         "$name" 2>/dev/null || echo "missing")
    if [ "$health" = "healthy" ]; then ok "$name is healthy"; return 0; fi
    if [ "$health" = "none" ] && [ "$state" = "running" ]; then ok "$name is running"; return 0; fi
    if [ "$state" = "exited" ] || [ "$state" = "dead" ]; then
      fail "$name exited unexpectedly — run: docker logs $name"
    fi
    sleep 5; elapsed=$((elapsed + 5))
  done
  fail "$name did not become healthy within ${max}s — run: docker logs $name"
}

echo ""
echo "========================================"
echo "  DBCostOps Stack Startup"
echo "========================================"
echo ""

# ── STAGE 1: Databases ─────────────────────
log "Stage 1/5 — Building and starting databases..."
$COMPOSE up -d --build postgres-primary mysql-primary mongodb-primary

wait_for_container dbcostops-postgres-primary 90
wait_for_container dbcostops-mysql-primary    90
wait_for_container dbcostops-mongodb-primary  90

# ── STAGE 2: Elasticsearch ─────────────────
log "Stage 2/5 — Starting Elasticsearch..."
$COMPOSE up -d --build elasticsearch

log "Waiting for Elasticsearch cluster health (up to 120s)..."
elapsed=0
until curl -sf http://localhost:9200/_cluster/health 2>/dev/null | grep -qE '"status":"(green|yellow)"'; do
  [ $elapsed -ge 120 ] && fail "Elasticsearch did not become healthy — run: docker logs dbcostops-elasticsearch"
  sleep 10; elapsed=$((elapsed + 10))
done
ok "Elasticsearch is ready"

# ── STAGE 3: Logstash + Kibana ─────────────
log "Stage 3/5 — Starting Logstash and Kibana..."
$COMPOSE up -d --build logstash kibana

wait_for_container dbcostops-logstash 120
wait_for_container dbcostops-kibana   120

# ── STAGE 4: Monitoring ────────────────────
log "Stage 4/5 — Starting Prometheus and Grafana..."
$COMPOSE up -d --build prometheus grafana

wait_for_container dbcostops-prometheus 60
wait_for_container dbcostops-grafana    60

# ── STAGE 5: Application services ─────────
log "Stage 5/5 — Starting Cost Engine API and Rundeck..."
$COMPOSE up -d --build cost-engine-api rundeck

wait_for_container dbcostops-cost-engine 60
wait_for_container dbcostops-rundeck     120

echo ""
echo "========================================"
ok "All services are up!"
echo "========================================"
echo ""
echo "  PostgreSQL     → localhost:5433"
echo "  MySQL          → localhost:3306"
echo "  MongoDB        → localhost:27017"
echo "  Elasticsearch  → http://localhost:9200"
echo "  Kibana         → http://localhost:5601"
echo "  Logstash API   → http://localhost:9600"
echo "  Prometheus     → http://localhost:9091"
echo "  Grafana        → http://localhost:3001   (admin / admin123)"
echo "  Cost Engine    → http://localhost:8000"
echo "  Rundeck        → http://localhost:4440   (admin / admin)"
echo ""
echo "Run ./scripts/test.sh to validate all services."
echo ""
