#!/usr/bin/env python3
"""
Shared Prometheus client utility for DBCostOps
Used by anomaly_detector, cost_forecaster, and optimizer
"""

import requests
from typing import Dict, Any


class PrometheusClient:
    """Shared PromQL query client"""

    def __init__(self, prometheus_url: str = "http://localhost:9090"):
        self.prometheus_url = prometheus_url

    def query(self, promql_query: str) -> Dict[str, Any]:
        """Execute a PromQL instant query against Prometheus"""
        try:
            response = requests.get(
                f"{self.prometheus_url}/api/v1/query",
                params={"query": promql_query},
                timeout=10
            )
            return response.json()
        except Exception as e:
            return {"error": f"PromQL query failed: {str(e)}"}

    def query_range(self, promql_query: str, start: str, end: str, step: str = "24h") -> Dict[str, Any]:
        """Execute a PromQL range query against Prometheus"""
        try:
            response = requests.get(
                f"{self.prometheus_url}/api/v1/query_range",
                params={"query": promql_query, "start": start, "end": end, "step": step},
                timeout=10
            )
            return response.json()
        except Exception as e:
            return {"error": f"PromQL range query failed: {str(e)}"}

    def extract_value(self, response: Dict[str, Any]) -> float:
        """Extract a single metric value from a Prometheus instant query response"""
        try:
            if "data" in response and "result" in response["data"]:
                result = response["data"]["result"]
                if result and "value" in result[0]:
                    return float(result[0]["value"][1])
            return 0.0
        except (IndexError, KeyError, ValueError, TypeError):
            return 0.0

    def extract_range_values(self, response: Dict[str, Any]) -> list:
        """Extract a list of float values from a Prometheus range query response"""
        try:
            if response.get("data", {}).get("result"):
                values = response["data"]["result"][0].get("values", [])
                return [float(v[1]) for v in values]
            return []
        except (IndexError, KeyError, ValueError, TypeError):
            return []
