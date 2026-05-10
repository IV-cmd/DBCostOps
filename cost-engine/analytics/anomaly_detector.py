#!/usr/bin/env python3
"""
Real anomaly detector for DBCostOps using PromQL queries
"""

import requests
from typing import Dict, Any
from datetime import datetime, timedelta
import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'pricing-api'))
from pricing import PricingDatabase

class AnomalyDetector:
    """Real anomaly detection using PromQL queries"""
    
    def __init__(self, prometheus_url: str = "http://localhost:9090", threshold: float = 2.0):
        self.prometheus_url = prometheus_url
        self.threshold = threshold
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
    
    def get_current_metrics(self, database_type: str, instance_type: str, node_name: str) -> Dict[str, Any]:
        """Get current metrics using PromQL"""
        try:
            # PromQL queries for current resource usage
            cpu_query = f'rate(process_cpu_seconds_total{{node="{node_name}"}}[5m]) * 100'
            memory_query = f'process_resident_memory_bytes{{node="{node_name}"}} / 1024 / 1024 / 1024'
            storage_query = f'database_storage_gb{{node="{node_name}"}}'
            
            # Get connection count based on database type
            if database_type == "postgresql":
                conn_query = f'pg_stat_activity_numbackends{{node="{node_name}"}}'
            elif database_type == "mysql":
                conn_query = f'mysql_global_status_threads_connected{{node="{node_name}"}}'
            else:
                conn_query = f'mongodb_connections{{node="{node_name}"}}'
            
            # Query CPU usage
            cpu_response = self._query_prometheus(cpu_query)
            cpu_usage = self._extract_metric_value(cpu_response)
            
            # Query memory usage
            memory_response = self._query_prometheus(memory_query)
            memory_usage = self._extract_metric_value(memory_response)
            
            # Query storage usage
            storage_response = self._query_prometheus(storage_query)
            storage_gb = self._extract_metric_value(storage_response)
            
            # Query connection count
            conn_response = self._query_prometheus(conn_query)
            connections = self._extract_metric_value(conn_response)
            
            return {
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage,
                "storage_gb": storage_gb,
                "connections": connections,
                "promql_queries": {
                    "cpu": cpu_query,
                    "memory": memory_query,
                    "storage": storage_query,
                    "connections": conn_query
                }
            }
        except Exception as e:
            print(f"Error getting current metrics: {e}")
            return {}
    
    def detect_cost_anomaly(self, database_type: str, instance_type: str, node_name: str, days: int = 30) -> Dict[str, Any]:
        """Detect cost anomaly using real PromQL metrics"""
        
        # Get historical costs
        historical_costs = self.get_historical_costs(node_name, days)
        
        # Get current metrics and calculate current cost
        current_metrics = self.get_current_metrics(database_type, instance_type, node_name)
        
        if not current_metrics:
            return {"anomaly": False, "reason": "Unable to fetch current metrics"}
        
        # Calculate current cost
        current_cost_result = self.pricing.calculate_monthly_cost(
            database_type=database_type,
            instance_type=instance_type,
            storage_gb=current_metrics.get("storage_gb", 100)
        )
        
        if "error" in current_cost_result:
            return {"anomaly": False, "reason": "Unable to calculate current cost"}
        
        current_cost = current_cost_result["total_monthly_cost"]
        
        if not historical_costs:
            return {"anomaly": False, "reason": "No historical data available"}
        
        # Statistical anomaly detection
        mean_cost = sum(historical_costs) / len(historical_costs)
        std_cost = (sum((x - mean_cost) ** 2 for x in historical_costs) / len(historical_costs)) ** 0.5
        
        if std_cost == 0:
            return {"anomaly": False, "reason": "No cost variation detected"}
        
        z_score = abs(current_cost - mean_cost) / std_cost
        is_anomaly = abs(z_score) > self.threshold
        
        # Additional resource-based anomaly detection
        resource_anomaly = self._detect_resource_anomaly(current_metrics)
        
        return {
            "anomaly": is_anomaly or resource_anomaly["detected"],
            "z_score": round(z_score, 2),
            "threshold": self.threshold,
            "current_cost": round(current_cost, 2),
            "mean_cost": round(mean_cost, 2),
            "std_cost": round(std_cost, 2),
            "historical_data_points": len(historical_costs),
            "current_metrics": current_metrics,
            "resource_anomaly": resource_anomaly,
            "anomaly_type": self._classify_anomaly(z_score, resource_anomaly),
            "severity": self._calculate_severity(z_score, resource_anomaly),
            "promql_queries": {
                "historical_costs": f'database_monthly_cost{{node="{node_name}"}}',
                "current_cpu": f'rate(process_cpu_seconds_total{{node="{node_name}"}}[5m]) * 100',
                "current_memory": f'process_resident_memory_bytes{{node="{node_name}"}} / 1024 / 1024 / 1024',
                "current_storage": f'database_storage_gb{{node="{node_name}"}}',
                "connections": f'pg_stat_activity_numbackends{{node="{node_name}"}}' if database_type == "postgresql" else f'mysql_global_status_threads_connected{{node="{node_name}"}}' if database_type == "mysql" else f'mongodb_connections{{node="{node_name}"}}'
            },
            "timestamp": datetime.now().isoformat()
        }
    
    def _detect_resource_anomaly(self, metrics: Dict[str, Any]) -> Dict[str, Any]:
        """Detect resource usage anomalies"""
        cpu_usage = metrics.get("cpu_usage", 0)
        memory_usage = metrics.get("memory_usage", 0)
        connections = metrics.get("connections", 0)
        
        anomalies = []
        
        if cpu_usage > 90:
            anomalies.append("High CPU usage")
        elif cpu_usage < 10:
            anomalies.append("Very low CPU usage")
        
        if memory_usage > 90:
            anomalies.append("High memory usage")
        elif memory_usage < 10:
            anomalies.append("Very low memory usage")
        
        if connections > 100:
            anomalies.append("High connection count")
        
        return {
            "detected": len(anomalies) > 0,
            "anomalies": anomalies,
            "cpu_usage": cpu_usage,
            "memory_usage": memory_usage,
            "connections": connections
        }
    
    def _classify_anomaly(self, z_score: float, resource_anomaly: Dict[str, Any]) -> str:
        """Classify type of anomaly"""
        if abs(z_score) > self.threshold:
            return "cost_spike"
        elif resource_anomaly["detected"]:
            return "resource_anomaly"
        else:
            return "normal"
    
    def _calculate_severity(self, z_score: float, resource_anomaly: Dict[str, Any]) -> str:
        """Calculate anomaly severity"""
        if abs(z_score) > 3 or len(resource_anomaly["anomalies"]) > 2:
            return "critical"
        elif abs(z_score) > 2.5 or len(resource_anomaly["anomalies"]) > 1:
            return "high"
        elif abs(z_score) > 2 or len(resource_anomaly["anomalies"]) > 0:
            return "medium"
        else:
            return "low"
    
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
