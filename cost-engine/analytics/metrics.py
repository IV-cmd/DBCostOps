#!/usr/bin/env python3
"""
Metrics collection from Prometheus using real PromQL queries
"""

import json
import requests
import psutil
from datetime import datetime
from typing import Dict, Any

class MetricsCollector:
    """Metrics collector from Prometheus using real PromQL queries"""
    
    def __init__(self, prometheus_url: str = "http://localhost:9090", 
                 cost_api_url: str = "http://localhost:8000"):
        self.prometheus_url = prometheus_url
        self.cost_api_url = cost_api_url
    
    def collect_postgresql_metrics(self, node_name: str = "postgres-primary") -> Dict[str, Any]:
        """Collect PostgreSQL metrics using real PromQL queries"""
        try:
            # Real PromQL queries for PostgreSQL
            active_connections_query = 'pg_stat_activity_numbackends{job="postgres"}'
            db_size_query = 'pg_database_size_bytes{datname="dbcostops"}'
            cpu_query = 'rate(process_cpu_seconds_total{job="postgres"}[5m]) * 100'
            memory_query = 'process_resident_memory_bytes{job="postgres"} / 1024 / 1024 / 1024'
            
            # Query active connections
            conn_response = self._query_prometheus(active_connections_query)
            active_connections = self._extract_metric_value(conn_response)
            
            # Query database size
            size_response = self._query_prometheus(db_size_query)
            db_size_bytes = self._extract_metric_value(size_response)
            db_size_gb = round(db_size_bytes / (1024**3), 2) if db_size_bytes > 0 else 0
            
            # Query CPU usage
            cpu_response = self._query_prometheus(cpu_query)
            cpu_usage = self._extract_metric_value(cpu_response)
            
            # Query memory usage
            memory_response = self._query_prometheus(memory_query)
            memory_usage = self._extract_metric_value(memory_response)
            
            return {
                "node_name": node_name,
                "database_type": "postgresql",
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage,
                "connections": {
                    "active": active_connections,
                    "data_source": "prometheus"
                },
                "storage_gb": db_size_gb,
                "performance": {
                    "connections_per_minute": active_connections,
                    "data_source": "prometheus"
                },
                "promql_queries": {
                    "active_connections": active_connections_query,
                    "db_size": db_size_query,
                    "cpu": cpu_query,
                    "memory": memory_query
                },
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {"error": f"PostgreSQL metrics collection failed: {str(e)}"}
    
    def collect_mysql_metrics(self, node_name: str = "mysql-primary") -> Dict[str, Any]:
        """Collect MySQL metrics using real PromQL queries"""
        try:
            # Real PromQL queries for MySQL
            connections_query = 'mysql_global_status_threads_connected{job="mysql"}'
            db_size_query = 'mysql_info_schema_data_length{schema="dbcostops"}'
            cpu_query = 'rate(process_cpu_seconds_total{job="mysql"}[5m]) * 100'
            memory_query = 'process_resident_memory_bytes{job="mysql"} / 1024 / 1024 / 1024'
            
            # Query connections
            conn_response = self._query_prometheus(connections_query)
            connections = self._extract_metric_value(conn_response)
            
            # Query database size
            size_response = self._query_prometheus(db_size_query)
            storage_bytes = self._extract_metric_value(size_response)
            storage_gb = round(storage_bytes / (1024**3), 2) if storage_bytes > 0 else 0
            
            # Query CPU usage
            cpu_response = self._query_prometheus(cpu_query)
            cpu_usage = self._extract_metric_value(cpu_response)
            
            # Query memory usage
            memory_response = self._query_prometheus(memory_query)
            memory_usage = self._extract_metric_value(memory_response)
            
            return {
                "node_name": node_name,
                "database_type": "mysql",
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage,
                "connections": {
                    "active": connections,
                    "data_source": "prometheus"
                },
                "storage_gb": storage_gb,
                "performance": {
                    "connections_per_minute": connections,
                    "data_source": "prometheus"
                },
                "promql_queries": {
                    "connections": connections_query,
                    "db_size": db_size_query,
                    "cpu": cpu_query,
                    "memory": memory_query
                },
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {"error": f"MySQL metrics collection failed: {str(e)}"}
    
    def collect_mongodb_metrics(self, node_name: str = "mongodb-primary") -> Dict[str, Any]:
        """Collect MongoDB metrics using real PromQL queries"""
        try:
            # Real PromQL queries for MongoDB
            connections_query = 'mongodb_connections{job="mongodb"}'
            db_size_query = 'mongodb_dbstats_storage_size_bytes{db="dbcostops"}'
            cpu_query = 'rate(process_cpu_seconds_total{job="mongodb"}[5m]) * 100'
            memory_query = 'process_resident_memory_bytes{job="mongodb"} / 1024 / 1024 / 1024'
            
            # Query connections
            conn_response = self._query_prometheus(connections_query)
            connections = self._extract_metric_value(conn_response)
            
            # Query database size
            size_response = self._query_prometheus(db_size_query)
            storage_bytes = self._extract_metric_value(size_response)
            storage_gb = round(storage_bytes / (1024**3), 2) if storage_bytes > 0 else 0
            
            # Query CPU usage
            cpu_response = self._query_prometheus(cpu_query)
            cpu_usage = self._extract_metric_value(cpu_response)
            
            # Query memory usage
            memory_response = self._query_prometheus(memory_query)
            memory_usage = self._extract_metric_value(memory_response)
            
            return {
                "node_name": node_name,
                "database_type": "mongodb",
                "cpu_usage": cpu_usage,
                "memory_usage": memory_usage,
                "connections": {
                    "active": connections,
                    "data_source": "prometheus"
                },
                "storage_gb": storage_gb,
                "performance": {
                    "connections_per_minute": connections,
                    "data_source": "prometheus"
                },
                "promql_queries": {
                    "connections": connections_query,
                    "db_size": db_size_query,
                    "cpu": cpu_query,
                    "memory": memory_query
                },
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {"error": f"MongoDB metrics collection failed: {str(e)}"}
    
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
    
    def send_to_cost_engine(self, metrics: Dict[str, Any]) -> bool:
        """Send metrics to cost engine"""
        try:
            response = requests.post(
                f"{self.cost_api_url}/metrics/store",
                json=metrics,
                timeout=10
            )
            return response.status_code == 200
        except:
            return False
