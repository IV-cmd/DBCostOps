#!/usr/bin/env python3
"""
Real cost calculation for DBCostOps
"""

import json
from typing import Dict, Any
from datetime import datetime
import os

class PricingDatabase:
    """Real cost calculation based on configurable pricing source"""
    
    def __init__(self):
        # Load pricing from external JSON file
        self.load_pricing_data()
    
    def load_pricing_data(self):
        """Load pricing data from JSON file"""
        try:
            pricing_file = os.path.join(os.path.dirname(__file__), '..', 'pricing', 'pricing-source.json')
            with open(pricing_file, 'r') as f:
                self.pricing_data = json.load(f)
        except FileNotFoundError:
            # Fallback to default pricing if file not found
            self.pricing_data = self._get_default_pricing()
        except Exception as e:
            print(f"Error loading pricing data: {e}")
            self.pricing_data = self._get_default_pricing()
    
    def _get_default_pricing(self) -> Dict[str, Any]:
        """Fallback default pricing"""
        return {
            "base_rates": {
                "compute_per_cpu_hour": 0.05,
                "memory_per_gb_hour": 0.01,
                "storage_per_gb_month": 0.10,
                "network_per_gb_month": 0.02
            },
            "database_overheads": {
                "postgresql": 1.2,
                "mysql": 1.15,
                "mongodb": 1.25
            },
            "regions": {
                "us-east-1": {"multiplier": 1.0, "name": "US East (N. Virginia)"},
                "us-west-2": {"multiplier": 1.05, "name": "US West (Oregon)"},
                "eu-west-1": {"multiplier": 1.1, "name": "EU West (Ireland)"},
                "ap-southeast-1": {"multiplier": 1.15, "name": "AP Southeast (Singapore)"}
            },
            "discounts": {
                "multi_az": 0.9,
                "reserved_1_year": 0.8,
                "reserved_3_year": 0.6
            },
            "instance_types": {
                "micro": {"cpu": 1, "memory_gb": 1, "baseline_multiplier": 1.0},
                "small": {"cpu": 1, "memory_gb": 2, "baseline_multiplier": 1.5},
                "medium": {"cpu": 2, "memory_gb": 4, "baseline_multiplier": 2.0},
                "large": {"cpu": 2, "memory_gb": 8, "baseline_multiplier": 3.0},
                "xlarge": {"cpu": 4, "memory_gb": 16, "baseline_multiplier": 5.0}
            }
        }
    
    def calculate_monthly_cost(self, database_type: str, instance_type: str, 
                          storage_gb: float = 100.0, region: str = "us-east-1",
                          multi_az: bool = True, reserved_term: str = "on_demand") -> Dict[str, Any]:
        """Calculate real monthly cost based on resource-based pricing"""
        
        # Input validation
        if not database_type or database_type.strip() == "":
            return {"error": "Database type is required"}
        
        if not instance_type or instance_type.strip() == "":
            return {"error": "Instance type is required"}
        
        if storage_gb < 0:
            return {"error": "Storage GB must be positive"}
        
        if database_type not in self.pricing_data.get("database_overheads", {}):
            return {"error": f"Database type '{database_type}' not supported"}
        
        if instance_type not in self.pricing_data.get("instance_types", {}):
            return {"error": f"Instance type '{instance_type}' not supported"}
        
        # Get base rates and multipliers
        base_rates = self.pricing_data["base_rates"]
        db_overhead = self.pricing_data["database_overheads"][database_type]
        region_data = self.pricing_data["regions"].get(region, {"multiplier": 1.0})
        discounts = self.pricing_data["discounts"]
        instance_types = self.pricing_data["instance_types"]
        
        # Get instance configuration
        instance_config = instance_types[instance_type]
        cpu_count = instance_config["cpu"]
        memory_gb = instance_config["memory_gb"]
        baseline_multiplier = instance_config["baseline_multiplier"]
        
        # Calculate compute cost
        compute_cost_per_hour = (
            (cpu_count * base_rates["compute_per_cpu_hour"] + 
             memory_gb * base_rates["memory_per_gb_hour"]) * 
            baseline_multiplier * db_overhead
        )
        monthly_compute = compute_cost_per_hour * 24 * 30  # 30 days
        
        # Calculate storage cost
        monthly_storage = storage_gb * base_rates["storage_per_gb_month"]
        
        # Apply region multiplier
        region_multiplier = region_data["multiplier"]
        
        # Apply multi-AZ discount
        multi_az_discount = discounts["multi_az"] if multi_az else 1.0
        
        # Apply reserved term discount
        reserved_discount = {
            "on_demand": 1.0,
            "1_year": discounts["reserved_1_year"],
            "3_year": discounts["reserved_3_year"]
        }.get(reserved_term, 1.0)
        
        # Validate reserved term
        if reserved_term not in ["on_demand", "1_year", "3_year"]:
            return {"error": "Reserved term must be 'on_demand', '1_year', or '3_year'"}
        
        # Total monthly cost
        total_monthly = (monthly_compute + monthly_storage) * region_multiplier * multi_az_discount * reserved_discount
        
        return {
            "total_monthly_cost": round(total_monthly, 2),
            "cost_breakdown": {
                "compute_cost": round(monthly_compute * region_multiplier * multi_az_discount * reserved_discount, 2),
                "storage_cost": round(monthly_storage * region_multiplier * multi_az_discount * reserved_discount, 2),
                "compute_cost_per_hour": round(compute_cost_per_hour, 4),
                "base_rates": base_rates,
                "region_multiplier": region_multiplier,
                "multi_az_discount": multi_az_discount,
                "reserved_discount": reserved_discount,
                "db_overhead": db_overhead,
                "instance_config": instance_config
            }
        }
    
    def get_pricing_info(self) -> Dict[str, Any]:
        """Get current pricing configuration"""
        return {
            "pricing_model": self.pricing_data.get("pricing_model", "resource_based"),
            "currency": self.pricing_data.get("currency", "USD"),
            "last_updated": self.pricing_data.get("last_updated", datetime.now().isoformat()),
            "base_rates": self.pricing_data.get("base_rates", {}),
            "database_overheads": self.pricing_data.get("database_overheads", {}),
            "regions": self.pricing_data.get("regions", {}),
            "discounts": self.pricing_data.get("discounts", {}),
            "instance_types": self.pricing_data.get("instance_types", {})
        }
