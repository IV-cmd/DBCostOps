#!/usr/bin/env python3
"""
Real cost forecaster for DBCostOps using PromQL queries
"""

import requests
from typing import Dict, Any
from datetime import datetime, timedelta
import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'pricing-api'))
from pricing import PricingDatabase

class CostForecaster:
    """Real cost forecasting using PromQL queries"""
    
    def __init__(self, prometheus_url: str = "http://localhost:9090"):
        self.prometheus_url = prometheus_url
        self.pricing = PricingDatabase()
    
    def get_historical_costs(self, node_name: str, days: int = 30) -> list:
        """Get historical cost data using PromQL"""
        try:
            # PromQL query for historical cost data
            cost_query = f'database_monthly_cost{{node="{node_name}"}}'
            
            response = requests.get(
                f"{self.prometheus_url}/api/v1/query_range",
                params={
                    "query": cost_query,
                    "start": (datetime.now() - timedelta(days=days)).isoformat(),
                    "end": datetime.now().isoformat(),
                    "step": "24h"
                },
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("data", {}).get("result"):
                    result = data["data"]["result"][0]
                    values = result.get("values", [])
                    return [float(value[1]) for value in values]
            
            return []
        except Exception as e:
            print(f"Error getting historical costs: {e}")
            return []
    
    def get_current_metrics(self, node_name: str) -> Dict[str, Any]:
        """Get current metrics using PromQL"""
        try:
            # PromQL queries for current resource usage
            cpu_query = f'rate(process_cpu_seconds_total{{node="{node_name}"}}[5m]) * 100'
            memory_query = f'process_resident_memory_bytes{{node="{node_name}"}} / 1024 / 1024 / 1024'
            storage_query = f'database_storage_gb{{node="{node_name}"}}'
            
            # Query CPU usage
            cpu_response = self._query_prometheus(cpu_query)
            cpu_usage = self._extract_metric_value(cpu_response)
            
            # Query memory usage
            memory_response = self._query_prometheus(memory_query)
            memory_usage = self._extract_metric_value(memory_response)
            
            # Query storage usage
            storage_response = self._query_prometheus(storage_query)
            storage_gb = self._extract_metric_value(storage_response)
            
            return {
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage,
                "storage_gb": storage_gb,
                "promql_queries": {
                    "cpu": cpu_query,
                    "memory": memory_query,
                    "storage": storage_query
                }
            }
        except Exception as e:
            print(f"Error getting current metrics: {e}")
            return {}
    
    def forecast_cost(self, database_type: str, current_instance: str, 
                   node_name: str, days: int = 30) -> Dict[str, Any]:
        """Forecast cost based on real PromQL metrics"""
        
        # Get historical costs
        historical_costs = self.get_historical_costs(node_name, days)
        
        # Get current metrics
        current_metrics = self.get_current_metrics(node_name)
        
        # Calculate current cost
        current_cost_result = self.pricing.calculate_monthly_cost(
            database_type=database_type,
            instance_type=current_instance,
            storage_gb=current_metrics.get("storage_gb", 100)
        )
        
        if "error" in current_cost_result:
            return {"error": current_cost_result["error"]}
        
        current_cost = current_cost_result["total_monthly_cost"]
        
        if not historical_costs:
            # If no historical data, use current metrics to forecast
            forecast = self._forecast_from_metrics(current_metrics, current_cost, days)
        else:
            # Use historical data for better forecasting
            forecast = self._forecast_from_history(historical_costs, current_cost, days)
        
        return {
            "current_cost": current_cost,
            "forecast_cost": round(forecast["cost"], 2),
            "trend_percentage": round(forecast["trend"], 2),
            "confidence": forecast["confidence"],
            "forecast_method": forecast["method"],
            "historical_data_points": len(historical_costs),
            "current_metrics": current_metrics,
            "days": days,
            "promql_queries": {
                "historical_costs": f'database_monthly_cost{{node="{node_name}"}}',
                "current_cpu": f'rate(process_cpu_seconds_total{{node="{node_name}"}}[5m]) * 100',
                "current_memory": f'process_resident_memory_bytes{{node="{node_name}"}} / 1024 / 1024 / 1024',
                "current_storage": f'database_storage_gb{{node="{node_name}"}}'
            },
            "timestamp": datetime.now().isoformat()
        }
    
    def _forecast_from_history(self, historical_costs: list, current_cost: float, days: int) -> Dict[str, Any]:
        """Forecast using historical cost data"""
        # Calculate trend using linear regression
        if len(historical_costs) < 2:
            return {
                "cost": current_cost,
                "trend": 0,
                "confidence": 0.3,
                "method": "insufficient_data"
            }
        
        # Simple linear trend calculation
        avg_cost = sum(historical_costs) / len(historical_costs)
        recent_avg = sum(historical_costs[-7:]) / min(7, len(historical_costs))
        
        # Calculate trend
        if recent_avg > avg_cost:
            trend = (recent_avg - avg_cost) / avg_cost * 100
        else:
            trend = (recent_avg - avg_cost) / avg_cost * 100
        
        # Apply trend to forecast
        trend_factor = 1 + (trend / 100) * (days / 30)
        forecast_cost = current_cost * trend_factor
        
        # Calculate confidence based on data consistency
        variance = sum((x - avg_cost) ** 2 for x in historical_costs) / len(historical_costs)
        std_dev = variance ** 0.5
        confidence = max(0.3, min(0.9, 1 - (std_dev / avg_cost)))
        
        return {
            "cost": forecast_cost,
            "trend": trend,
            "confidence": round(confidence, 2),
            "method": "historical_trend"
        }
    
    def _forecast_from_metrics(self, current_metrics: Dict[str, Any], current_cost: float, days: int) -> Dict[str, Any]:
        """Forecast using current resource metrics"""
        cpu_usage = current_metrics.get("cpu_usage", 50)
        memory_usage = current_metrics.get("memory_usage", 50)
        storage_gb = current_metrics.get("storage_gb", 100)
        
        # Predict growth based on resource utilization
        growth_factor = 1.0
        
        # High utilization suggests potential growth
        if cpu_usage > 80 or memory_usage > 80:
            growth_factor = 1.05  # 5% growth
        elif cpu_usage > 60 or memory_usage > 60:
            growth_factor = 1.02  # 2% growth
        elif cpu_usage < 30 and memory_usage < 30:
            growth_factor = 0.98  # 2% reduction possible
        
        # Storage growth prediction
        storage_growth = min(0.1, storage_gb * 0.01)  # Max 10% growth
        
        forecast_cost = current_cost * growth_factor + storage_growth
        
        return {
            "cost": forecast_cost,
            "trend": (growth_factor - 1) * 100,
            "confidence": 0.5,
            "method": "resource_based"
        }
    
    def _query_prometheus(self, promql_query: str) -> Dict[str, Any]:
        """Execute PromQL query against Prometheus"""
        try:
            response = requests.get(
                f"{self.prometheus_url}/api/v1/query",
                params={"query": promql_query},
                timeout=10
            )
            return response.json()
        except Exception as e:
            return {"error": f"PromQL query failed: {str(e)}"}
    
    def _extract_metric_value(self, response: Dict[str, Any]) -> float:
        """Extract metric value from Prometheus response"""
        try:
            if "data" in response and "result" in response["data"]:
                result = response["data"]["result"]
                if result and "value" in result[0]:
                    return float(result[0]["value"][1])
            return 0.0
        except (IndexError, KeyError, ValueError, TypeError):
            return 0.0
