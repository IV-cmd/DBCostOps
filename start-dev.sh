#!/bin/bash
# Quick Development Start
echo "🚀 Quick Start - DBCostOps Development"

# Start Cost Engine API only
cd cost-engine
python3 -m venv venv
source venv/bin/activate

# Install only required dependencies for API
echo "📚 Installing API dependencies..."
pip install fastapi==0.104.1 uvicorn==0.24.0 sqlalchemy==2.0.23 psycopg2-binary==2.9.9 pymysql==1.1.0 pymongo==4.6.0 elasticsearch==8.11.0 prometheus-client==0.19.0 pandas==2.1.4 numpy==1.26.2 scikit-learn==1.3.2 pydantic==2.5.0 python-multipart==0.0.6

echo "🔧 Starting Cost Engine API..."
cd pricing-api
uvicorn cost-api:app --host 0.0.0.0 --port 8000 --reload

echo "✅ API running at http://localhost:8000"
echo "📊 API Docs: http://localhost:8000/docs"
