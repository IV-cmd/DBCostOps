#!/bin/bash
# DBCostOps - Stop and optionally clean up all services

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE="docker compose -f $PROJECT_DIR/docker-compose.yml"

log()  { echo -e "${BLUE}[$(date +%T)]${NC} $*"; }
ok()   { echo -e "${GREEN}[$(date +%T)] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +%T)] ⚠${NC} $*"; }

PURGE=false
if [ "${1:-}" = "--purge" ]; then
  PURGE=true
  warn "Purge mode — all volumes and images will be deleted"
fi

echo ""
echo "========================================"
echo "  DBCostOps Stack Shutdown"
echo "========================================"
echo ""

log "Stopping all services..."
$COMPOSE down --remove-orphans

if [ "$PURGE" = true ]; then
  warn "Removing all volumes..."
  $COMPOSE down -v --remove-orphans

  warn "Removing built images..."
  docker images --filter "reference=dbcostops*" -q | xargs -r docker rmi -f
  docker image prune -f --filter "label=com.docker.compose.project=dbcostops" 2>/dev/null || true

  ok "All volumes and images removed"
else
  echo ""
  echo -e "  Data volumes preserved. To also delete volumes run:"
  echo -e "  ${YELLOW}./scripts/down.sh --purge${NC}"
fi

echo ""
ok "Stack is down"
echo ""
