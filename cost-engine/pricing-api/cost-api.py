#!/usr/bin/env python3
"""
Production-ready Cost API for DBCostOps
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, List, Optional
import json
import logging
from datetime import datetime
from pricing import PricingDatabase

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DBCostOps Cost API", version="1.0.0")

# Initialize pricing database
pricing_db = PricingDatabase()

# Pydantic models
class CostRequest(BaseModel):
    database_type: str
    instance_type: str
    storage_gb: float = 100.0
    region: str = "us-east-1"
    multi_az: bool = True
    reserved_term: str = "on_demand"

class CostResponse(BaseModel):
    database_type: str
    instance_type: str
    total_monthly_cost: float
    cost_breakdown: Dict
    timestamp: str

class OptimizationRequest(BaseModel):
    database_type: str
    current_instance: str
    cpu_usage: float
    memory_usage: float
    connections: int
    monthly_cost: float

class OptimizationResponse(BaseModel):
    current_instance: str
    recommended_instance: str
    estimated_savings: float
    savings_percentage: float
    confidence: float
    implementation_plan: List[str]

# Simple endpoints without /api/v1 prefix
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "DBCostOps Cost API", "timestamp": datetime.now().isoformat()}

@app.get("/")
async def root():
    """Root endpoint"""
    return {"service": "DBCostOps Cost API", "version": "1.0.0", "status": "running"}

@app.get("/regions")
async def list_regions():
    """List available regions"""
    try:
        regions = [
            {"code": code, "name": data["name"]}
            for code, data in pricing_db.pricing["regions"].items()
        ]
        
        return {
            "regions": regions,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Error listing regions: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/instances/{database_type}")
async def list_instances(database_type: str):
    """List available instances for database type"""
    try:
        if database_type not in pricing_db.pricing:
            raise HTTPException(status_code=404, detail="Database type not found")
        
        instances = [
            {"type": instance_type, **config}
            for instance_type, config in pricing_db.pricing[database_type].items()
        ]
        
        return {
            "database_type": database_type,
            "available_instances": instances,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Error listing instances: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/cost/calculate", response_model=CostResponse)
async def calculate_cost(request: CostRequest):
    """Calculate monthly cost for database configuration"""
    try:
        cost_data = pricing_db.calculate_monthly_cost(
            database_type=request.database_type,
            instance_type=request.instance_type,
            storage_gb=request.storage_gb,
            region=request.region,
            multi_az=request.multi_az,
            reserved_term=request.reserved_term
        )
        
        if "error" in cost_data:
            raise HTTPException(status_code=400, detail=cost_data["error"])
        
        return CostResponse(
            database_type=request.database_type,
            instance_type=request.instance_type,
            total_monthly_cost=cost_data["total_monthly_cost"],
            cost_breakdown=cost_data["cost_breakdown"],
            timestamp=datetime.now().isoformat()
        )
    except Exception as e:
        logger.error(f"Error calculating cost: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/optimize/recommend", response_model=OptimizationResponse)
async def optimize_instance(request: OptimizationRequest):
    """Get optimization recommendations"""
    try:
        from optimization.optimizer import SimpleOptimizer
        optimizer = SimpleOptimizer()
        
        recommendation = optimizer.optimize_instance(
            database_type=request.database_type,
            current_instance=request.current_instance,
            cpu_usage=request.cpu_usage,
            memory_usage=request.memory_usage
        )
        
        if "error" in recommendation:
            raise HTTPException(status_code=400, detail=recommendation["error"])
        
        return OptimizationResponse(
            current_instance=request.current_instance,
            recommended_instance=recommendation["recommended_instance"],
            estimated_savings=recommendation["estimated_savings"],
            savings_percentage=recommendation["savings_percentage"],
            confidence=recommendation["confidence"],
            implementation_plan=recommendation["implementation_plan"],
            timestamp=datetime.now().isoformat()
        )
    except Exception as e:
        logger.error(f"Error optimizing instance: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/metrics/store")
async def store_metrics(metrics: Dict):
    """Store metrics from external collectors"""
    try:
        # Simple metrics storage (in real implementation, this would go to database)
        logger.info(f"Received metrics: {metrics}")
        return {"status": "success", "stored": True}
    except Exception as e:
        logger.error(f"Error storing metrics: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
