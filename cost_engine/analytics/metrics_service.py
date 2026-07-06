#!/usr/bin/env python3
"""
Automated metrics collection service for DBCostOps
Runs continuously to collect real database metrics
"""

import os
import time
import logging
from datetime import datetime
from .database_collector import DatabaseMetricsCollector

class MetricsCollectionService:
    """Automated metrics collection service"""
    
    def __init__(self, collection_interval: int = 300):
        self.collector = DatabaseMetricsCollector()
        self.collection_interval = collection_interval  # 5 minutes default
        self.setup_logging()
    
    def setup_logging(self):
        """Setup logging for the service"""
        log_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'logs')
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(log_dir, 'metrics_collection.log')
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def run_collection_cycle(self):
        """Run one complete collection cycle"""
        try:
            self.logger.info("Starting metrics collection cycle")
            
            # Collect metrics from all databases
            metrics = self.collector.collect_all_metrics()
            
            # Log collection results
            for db_type, db_metrics in metrics.items():
                if 'error' in db_metrics:
                    self.logger.error(f"Failed to collect {db_type} metrics: {db_metrics['error']}")
                else:
                    self.logger.info(f"Successfully collected {db_type} metrics")
                    
                    # Store metrics in monitoring database
                    if self.collector.store_metrics(db_type, db_metrics):
                        self.logger.info(f"Stored {db_type} metrics successfully")
                    else:
                        self.logger.error(f"Failed to store {db_type} metrics")
            
            self.logger.info("Metrics collection cycle completed")
            
        except Exception as e:
            self.logger.error(f"Error in collection cycle: {str(e)}")
    
    def start_service(self):
        """Start the continuous metrics collection service"""
        self.logger.info("Starting DBCostOps Metrics Collection Service")
        self.logger.info(f"Collection interval: {self.collection_interval} seconds")
        
        try:
            while True:
                start_time = time.time()
                
                # Run collection cycle
                self.run_collection_cycle()
                
                # Calculate sleep time
                cycle_duration = time.time() - start_time
                sleep_time = max(0, self.collection_interval - cycle_duration)
                
                self.logger.info(f"Sleeping for {sleep_time:.2f} seconds")
                time.sleep(sleep_time)
                
        except KeyboardInterrupt:
            self.logger.info("Service stopped by user")
        except Exception as e:
            self.logger.error(f"Service crashed: {str(e)}")
        finally:
            self.cleanup()
    
    def cleanup(self):
        """Cleanup resources"""
        self.logger.info("Cleaning up resources")
        self.collector.close_connections()

# Service entry point
if __name__ == "__main__":
    service = MetricsCollectionService(collection_interval=300)  # 5 minutes
    service.start_service()
