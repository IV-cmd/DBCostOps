#!/usr/bin/env python3
"""
Real optimizer for DBCostOps using PromQL queries
"""

import requests
from typing import Dict, Any, Optional
from datetime import datetime
import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'pricing-api'))
from pricing import PricingDatabase
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from prometheus_client import PrometheusClient

class SimpleOptimizer:
    """Real optimization engine using PromQL queries"""
    
    def __init__(self, prometheus_url: str = "http://localhost:9090"):
        self.pricing = PricingDatabase()
        self.prometheus_url = prometheus_url
        self.prom = PrometheusClient(prometheus_url)
    
    def get_instance_metrics(self, node_name: str) -> Dict[str, Any]:
        """Get real metrics from Prometheus using PromQL"""
        try:
            # PromQL queries for current metrics
            cpu_query = f'rate(process_cpu_seconds_total{{node="{node_name}"}}[5m]) * 100'
            memory_query = f'process_resident_memory_bytes{{node="{node_name}"}} / 1024 / 1024 / 1024'
            
            # Get connection count based on database type
            if "postgresql" in node_name.lower():
                conn_query = f'pg_stat_activity_numbackends{{node="{node_name}"}}'
            elif "mysql" in node_name.lower():
                conn_query = f'mysql_global_status_threads_connected{{node="{node_name}"}}'
            else:
                conn_query = f'mongodb_connections{{node="{node_name}"}}'
            
            # Query CPU usage
            cpu_usage = self.prom.extract_value(self.prom.query(cpu_query))
            
            # Query memory usage
            memory_usage = self.prom.extract_value(self.prom.query(memory_query))
            
            # Query connection count
            connections = self.prom.extract_value(self.prom.query(conn_query))
            
            return {
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage,
                "connections": connections,
                "promql_queries": {
                    "cpu": cpu_query,
                    "memory": memory_query,
                    "connections": conn_query
                },
                "data_source": "prometheus",
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {"error": f"Metrics collection failed: {str(e)}"}
    
    def optimize_instance(self, database_type: str, current_instance: str,
                      node_name: Optional[str] = None) -> Dict[str, Any]:
        """Optimize instance based on real PromQL metrics"""
        
        # Infer node name from database type if not provided
        if node_name is None:
            node_name = f"{database_type}-primary"
        
        # Get real metrics from Prometheus
        metrics = self.get_instance_metrics(node_name)
        
        if "error" in metrics:
            return {"error": metrics["error"]}
        
        cpu_usage = metrics["cpu_usage"]
        memory_usage = metrics["memory_usage"]
        connections = metrics["connections"]
        
        # Get current instance cost
        current_cost_result = self.pricing.calculate_monthly_cost(database_type, current_instance)
        
        if "error" in current_cost_result:
            return {"error": current_cost_result["error"]}
        
        current_cost = current_cost_result["total_monthly_cost"]
        
        # Smart optimization logic based on real metrics
        if cpu_usage < 30 and memory_usage < 40 and connections < 10:
            # Underutilized - recommend downgrade
            if "micro" in current_instance:
                recommended_instance = current_instance  # Already smallest
                estimated_savings = 0
            elif "small" in current_instance:
                recommended_instance = "db.t3.micro"
                estimated_savings = current_cost * 0.4
            else:
                recommended_instance = "db.t3.small"
                estimated_savings = current_cost * 0.3
        
        elif cpu_usage > 80 or memory_usage > 85 or connections > 50:
            # Overutilized - recommend upgrade
            if "large" in current_instance or "xlarge" in current_instance:
                recommended_instance = current_instance  # Already largest
                estimated_savings = -current_cost * 0.2
            elif "medium" in current_instance:
                recommended_instance = "db.t3.large"
                estimated_savings = -current_cost * 0.15
            else:
                recommended_instance = "db.t3.medium"
                estimated_savings = -current_cost * 0.1
        
        else:
            # Optimally utilized - keep current
            recommended_instance = current_instance
            estimated_savings = 0
        
        # Calculate new instance cost
        new_cost = current_cost
        if recommended_instance != current_instance:
            new_cost_result = self.pricing.calculate_monthly_cost(database_type, recommended_instance)
            if "error" not in new_cost_result:
                new_cost = new_cost_result["total_monthly_cost"]
                estimated_savings = current_cost - new_cost
        
        savings_percentage = (estimated_savings / current_cost * 100) if current_cost > 0 else 0
        
        return {
            "current_instance": current_instance,
            "recommended_instance": recommended_instance,
            "estimated_savings": round(estimated_savings, 2),
            "savings_percentage": round(savings_percentage, 1),
            "current_cost": round(current_cost, 2),
            "recommended_cost": round(new_cost, 2),
            "metrics": metrics,
            "recommendation": self._get_recommendation(cpu_usage, memory_usage, connections),
            "confidence": self._calculate_confidence(cpu_usage, memory_usage, connections),
            "implementation_plan": self._get_implementation_plan(current_instance, recommended_instance),
            "promql_queries": {
                "current_cpu": f'rate(process_cpu_seconds_total{{node="{node_name}"}}[5m]) * 100',
                "current_memory": f'process_resident_memory_bytes{{node="{node_name}"}} / 1024 / 1024 / 1024',
                "current_connections": f'pg_stat_activity_numbackends{{node="{node_name}"}}' if database_type == "postgresql" else f'mysql_global_status_threads_connected{{node="{node_name}"}}' if database_type == "mysql" else f'mongodb_connections{{node="{node_name}"}}'
            },
            "timestamp": datetime.now().isoformat()
        }
    
    def _get_recommendation(self, cpu_usage: float, memory_usage: float, connections: float) -> str:
        """Get recommendation based on real metrics"""
        if cpu_usage < 30 and memory_usage < 40 and connections < 10:
            return "Low utilization detected - consider downgrading to save costs"
        elif cpu_usage > 80 or memory_usage > 85 or connections > 50:
            return "High utilization detected - consider upgrading for better performance"
        elif cpu_usage < 60 and memory_usage < 70:
            return "Optimal utilization - current instance is appropriate"
        else:
            return "Moderate utilization - monitor for optimization opportunities"
    
    def _calculate_confidence(self, cpu_usage: float, memory_usage: float, connections: float) -> float:
        """Calculate confidence level based on metrics stability"""
        if cpu_usage > 0 and memory_usage > 0 and connections > 0:
            # High confidence if all metrics are available
            if cpu_usage < 20 or cpu_usage > 90:
                return 0.9  # High confidence for clear signals
            elif 20 <= cpu_usage <= 80 and 20 <= memory_usage <= 80:
                return 0.7  # Medium confidence for normal ranges
            else:
                return 0.5  # Lower confidence for edge cases
        else:
            return 0.3  # Low confidence if metrics missing
    
    def _get_implementation_plan(self, current_instance: str, recommended_instance: str) -> list:
        """Get implementation plan for instance change"""
        if current_instance == recommended_instance:
            return ["No changes needed - current instance is optimal"]
        
        plan = [
            f"Schedule maintenance window for instance change",
            f"Backup current {current_instance} instance",
            f"Provision new {recommended_instance} instance",
            f"Migrate database to new instance",
            f"Update configuration and monitoring",
            f"Test performance and validate cost savings"
        ]
        
        return plan
    
