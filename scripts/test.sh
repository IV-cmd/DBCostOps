#!/bin/bash
# DBCostOps - Validate all services
# Run after ./scripts/up.sh

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

PASS=0; FAIL=0; WARN=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARN=$((WARN + 1)); }
section() { echo ""; echo -e "${BLUE}── $1 ─────────────────────────────${NC}"; }

# Helper: check HTTP endpoint
check_http() {
  local label=$1; local url=$2; local expect=${3:-""}
  response=$(curl -sf --max-time 10 "$url" 2>/dev/null) || { fail "$label — no response from $url"; return; }
  if [ -n "$expect" ] && ! echo "$response" | grep -q "$expect"; then
    fail "$label — unexpected response (expected '$expect') at $url"
  else
    pass "$label"
  fi
}

# Helper: check docker container is running
check_container() {
  local label=$1; local name=$2
  state=$(docker inspect --format='{{.State.Status}}' "$name" 2>/dev/null || echo "missing")
  health=$(docker inspect --format='{{.State.Health.Status}}' "$name" 2>/dev/null || echo "none")
  if [ "$state" = "running" ]; then
    if [ "$health" = "unhealthy" ]; then
      warn "$label — container running but health check FAILING (docker logs $name)"
    else
      pass "$label — container is $state ($health)"
    fi
  else
    fail "$label — container state: $state"
  fi
}

echo ""
echo "========================================"
echo "  DBCostOps Service Validation"
echo "========================================"

# ── Containers ─────────────────────────────
section "Container Status"
check_container "postgres-primary"  dbcostops-postgres-primary
check_container "mysql-primary"     dbcostops-mysql-primary
check_container "mongodb-primary"   dbcostops-mongodb-primary
check_container "elasticsearch"     dbcostops-elasticsearch
check_container "logstash"          dbcostops-logstash
check_container "kibana"            dbcostops-kibana
check_container "prometheus"        dbcostops-prometheus
check_container "grafana"           dbcostops-grafana
check_container "cost-engine-api"   dbcostops-cost-engine
check_container "rundeck"           dbcostops-rundeck

# ── PostgreSQL ─────────────────────────────
section "PostgreSQL"
if docker exec dbcostops-postgres-primary pg_isready -U dbcostops_user -d dbcostops -q 2>/dev/null; then
  pass "pg_isready — accepting connections"
else
  fail "pg_isready — not accepting connections"
fi

result=$(docker exec dbcostops-postgres-primary psql -U dbcostops_user -d dbcostops -c "SELECT version();" -t -A 2>/dev/null || echo "")
if echo "$result" | grep -q "PostgreSQL"; then
  pass "psql query — $(echo "$result" | head -1 | cut -c1-50)"
else
  fail "psql query — could not execute SELECT version()"
fi

# ── MySQL ──────────────────────────────────
section "MySQL"
if docker exec dbcostops-mysql-primary mysqladmin ping -u dbcostops_user --password=dbcostops_password --silent 2>/dev/null; then
  pass "mysqladmin ping — accepting connections"
else
  fail "mysqladmin ping — not accepting connections"
fi

result=$(docker exec dbcostops-mysql-primary mysql -u dbcostops_user --password=dbcostops_password -e "SELECT VERSION();" -s 2>/dev/null || echo "")
if [ -n "$result" ]; then
  pass "mysql query — version: $result"
else
  fail "mysql query — could not execute SELECT VERSION()"
fi

# ── MongoDB ────────────────────────────────
section "MongoDB"
result=$(docker exec dbcostops-mongodb-primary mongosh \
  --quiet \
  --eval "JSON.stringify(db.adminCommand({ping:1}))" \
  "mongodb://admin:admin_password@localhost:27017/admin" 2>/dev/null || echo "")
if echo "$result" | grep -q '"ok":1\|"ok" : 1'; then
  pass "mongosh ping — ok:1"
else
  fail "mongosh ping — no ok:1 response (got: $result)"
fi

# ── Elasticsearch ──────────────────────────
section "Elasticsearch"
check_http "cluster health API" "http://localhost:9200/_cluster/health" '"status"'

status=$(curl -sf --max-time 10 http://localhost:9200/_cluster/health 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null || echo "unknown")
case $status in
  green)  pass "cluster status: green" ;;
  yellow) warn "cluster status: yellow (single-node — expected)" ;;
  red)    fail "cluster status: red — cluster has issues" ;;
  *)      warn "cluster status: could not determine" ;;
esac

check_http "indices list" "http://localhost:9200/_cat/indices?v" ""

# ── Logstash ───────────────────────────────
section "Logstash"
check_http "Logstash node info"    "http://localhost:9600/"                      '"version"'
check_http "Logstash pipeline API" "http://localhost:9600/_node/pipelines?pretty" '"pipelines"'

# ── Kibana ─────────────────────────────────
section "Kibana"
check_http "Kibana status API" "http://localhost:5601/api/status" '"level"'

# ── Prometheus ─────────────────────────────
section "Prometheus"
check_http "Prometheus healthy"   "http://localhost:9091/-/healthy"  "Prometheus Server is Healthy"
check_http "Prometheus ready"     "http://localhost:9091/-/ready"    "Prometheus Server is Ready"
check_http "Prometheus targets"   "http://localhost:9091/api/v1/targets" '"status":"success"'

# ── Grafana ────────────────────────────────
section "Grafana"
check_http "Grafana health"       "http://localhost:3001/api/health"  '"database"'
response=$(curl -sf --max-time 10 -u admin:admin123 "http://localhost:3001/api/datasources" 2>/dev/null) || response=""
if [ -n "$response" ]; then pass "Grafana datasources (auth)"; else warn "Grafana datasources (auth) — empty or no response"; fi

# ── Cost Engine API ────────────────────────
section "Cost Engine API"
check_http "health endpoint"   "http://localhost:8000/health"  ""
check_http "OpenAPI docs"      "http://localhost:8000/docs"    ""
check_http "root endpoint"     "http://localhost:8000/"        '"status"'

# ── Rundeck ────────────────────────────────
section "Rundeck"
check_http "login page" "http://localhost:4440/user/login" ""

# ── Summary ────────────────────────────────
echo ""
echo "========================================"
echo -e "  ${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}  ${YELLOW}WARN: $WARN${NC}"
echo "========================================"
echo ""

if [ $FAIL -gt 0 ]; then
  echo -e "${RED}Some services failed validation. Check logs with:${NC}"
  echo "  docker logs <container-name>"
  echo ""
  exit 1
else
  echo -e "${GREEN}All required checks passed!${NC}"
  echo ""
  exit 0
fi
