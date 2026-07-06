#!/bin/bash

# DBCostOps Local Development Runner
# Run project locally without Docker

set -e

echo "🚀 Starting DBCostOps Local Development..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    exit 1
fi

# Check PostgreSQL
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is required but not installed."
    exit 1
fi

# Create virtual environment
echo "📦 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Start PostgreSQL (if not running)
if ! pg_isready -q; then
    echo "🗄️ Starting PostgreSQL..."
    brew services start postgresql || sudo systemctl start postgresql
fi

# Create database
echo "🗃️ Creating database..."
createdb dbcostops 2>/dev/null || true

# Start Cost Engine API
echo "🔧 Starting Cost Engine API..."
cd cost-engine
uvicorn cost-api:app --host 0.0.0.0 --port 8000 --reload &
COST_ENGINE_PID=$!
cd ..

# Wait for API to start
echo "⏳ Waiting for API to start..."
sleep 5

# Test API
echo "🧪 Testing API..."
curl -f http://localhost:8000/health || echo "⚠️ API health check failed"

echo "✅ DBCostOps is running locally!"
echo "📊 Cost Engine API: http://localhost:8000"
echo "📊 API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for interrupt
trap "echo '🛑 Stopping services...'; kill $COST_ENGINE_PID; exit" INT
wait
