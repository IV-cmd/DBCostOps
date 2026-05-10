#!/usr/bin/env python3
"""
Real database metrics collector for DBCostOps
Collects actual performance data from PostgreSQL, MySQL, and MongoDB
"""

import psycopg2
import mysql.connector
import pymongo
import psutil
import time
from datetime import datetime
from typing import Dict, Any, List
import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'pricing-api'))
from pricing import PricingDatabase

class DatabaseMetricsCollector:
    """Real database metrics collector"""
    
    def __init__(self):
        self.pricing = PricingDatabase()
        self.connections = {}
        self._init_connections()
    
    def _init_connections(self):
        """Initialize database connections"""
        try:
            # PostgreSQL connection
            self.connections['postgresql'] = psycopg2.connect(
                host='localhost',
                port=5432,
                database='dbcostops_monitoring',
                user='dbcostops_monitor',
                password='monitor_password'
            )
            
            # MySQL connection
            self.connections['mysql'] = mysql.connector.connect(
                host='localhost',
                port=3306,
                database='dbcostops_monitoring',
                user='dbcostops_monitor',
                password='monitor_password'
            )
            
            # MongoDB connection
            self.connections['mongodb'] = pymongo.MongoClient(
                'mongodb://dbcostops_monitor:monitor_password@localhost:27017/dbcostops_monitoring'
            )
            
        except Exception as e:
            print(f"Database connection error: {e}")
    
    def collect_postgresql_metrics(self) -> Dict[str, Any]:
        """Collect real PostgreSQL metrics"""
        try:
            conn = self.connections['postgresql']
            cursor = conn.cursor()
            
            # Real PostgreSQL performance queries
            queries = {
                'connections': """
                    SELECT 
                        count(*) as active_connections,
                        sum(CASE WHEN state = 'active' THEN 1 ELSE 0 END) as active_queries
                    FROM pg_stat_activity 
                    WHERE state = 'active'
                """,
                'database_size': """
                    SELECT 
                        pg_database_size('dbcostops_monitoring') as size_bytes,
                        pg_size_pretty(pg_database_size('dbcostops_monitoring')) as size_pretty
                """,
                'query_performance': """
                    SELECT 
                        avg(query_time) as avg_query_time,
                        max(query_time) as max_query_time,
                        sum(calls) as total_calls,
                        sum(total_exec_time) as total_exec_time
                    FROM pg_stat_user_functions 
                    WHERE calls > 0
                """,
                'resource_usage': """
                    SELECT 
                        (SELECT count(*) FROM pg_stat_activity) as total_connections,
                        (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') as active_connections,
                        (SELECT count(*) FROM pg_stat_activity WHERE state = 'idle') as idle_connections
                """
            }
            
            metrics = {}
            for name, query in queries.items():
                cursor.execute(query)
                result = cursor.fetchone()
                metrics[name] = result
            
            # Get system metrics
            system_metrics = self._get_system_metrics()
            metrics.update(system_metrics)
            
            cursor.close()
            return metrics
            
        except Exception as e:
            return {"error": f"PostgreSQL metrics collection failed: {str(e)}"}
    
    def collect_mysql_metrics(self) -> Dict[str, Any]:
        """Collect real MySQL metrics"""
        try:
            conn = self.connections['mysql']
            cursor = conn.cursor(dictionary=True)
            
            # Real MySQL performance queries
            queries = {
                'connections': """
                    SELECT 
                        COUNT(*) as active_connections,
                        SUM(CASE IF(command = 'Query', 1, 0)) as active_queries
                    FROM information_schema.processlist
                """,
                'database_size': """
                    SELECT 
                        SUM(data_length + index_length) as size_bytes,
                        ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as size_mb
                    FROM information_schema.tables 
                    WHERE table_schema = 'dbcostops_monitoring'
                """,
                'query_performance': """
                    SELECT 
                        AVG(timer_wait/1000000000000) as avg_query_time,
                        MAX(timer_wait/1000000000000) as max_query_time,
                        SUM(COUNT_STAR) as total_queries
                    FROM performance_schema.events_statements_summary_by_digest 
                    WHERE digest_text IS NOT NULL
                """,
                'resource_usage': """
                    SELECT 
                        (SELECT COUNT(*) FROM information_schema.processlist) as total_connections,
                        (SELECT COUNT(*) FROM information_schema.processlist WHERE command = 'Query') as active_connections,
                        (SELECT COUNT(*) FROM information_schema.processlist WHERE command = 'Sleep') as idle_connections
                """
            }
            
            metrics = {}
            for name, query in queries.items():
                cursor.execute(query)
                result = cursor.fetchone()
                metrics[name] = result
            
            # Get system metrics
            system_metrics = self._get_system_metrics()
            metrics.update(system_metrics)
            
            cursor.close()
            return metrics
            
        except Exception as e:
            return {"error": f"MySQL metrics collection failed: {str(e)}"}
    
    def collect_mongodb_metrics(self) -> Dict[str, Any]:
        """Collect real MongoDB metrics"""
        try:
            client = self.connections['mongodb']
            db = client['dbcostops_monitoring']
            
            # Real MongoDB performance queries
            server_status = db.command('serverStatus')
            db_stats = db.command('dbStats')
            
            metrics = {
                'connections': {
                    'current': server_status['connections']['current'],
                    'available': server_status['connections']['available'],
                    'total_created': server_status['connections']['totalCreated']
                },
                'database_size': {
                    'data_size': db_stats['dataSize'],
                    'storage_size': db_stats['storageSize'],
                    'index_size': db_stats['indexSize']
                },
                'operations': {
                    'queries': server_status['opcounters']['query'],
                    'inserts': server_status['opcounters']['insert'],
                    'updates': server_status['opcounters']['update'],
                    'deletes': server_status['opcounters']['delete']
                }
            }
            
            # Get system metrics
            system_metrics = self._get_system_metrics()
            metrics.update(system_metrics)
            
            return metrics
            
        except Exception as e:
            return {"error": f"MongoDB metrics collection failed: {str(e)}"}
    
    def _get_system_metrics(self) -> Dict[str, Any]:
        """Get real system metrics"""
        return {
            'cpu_usage': psutil.cpu_percent(interval=1),
            'memory_usage': psutil.virtual_memory().percent,
            'disk_usage': psutil.disk_usage('/').percent,
            'timestamp': datetime.now().isoformat()
        }
    
    def store_metrics(self, database_type: str, metrics: Dict[str, Any]) -> bool:
        """Store collected metrics in monitoring database"""
        try:
            # Store in PostgreSQL monitoring database only if not MySQL
            if database_type != 'mysql':
                conn = self.connections['postgresql']
                cursor = conn.cursor()
                
                # Store resource usage
                if 'cpu_usage' in metrics:
                    cursor.execute("""
                        INSERT INTO resource_usage 
                        (cpu_usage, memory_usage, disk_usage, connections, active_connections, idle_connections, cost_impact, node_name)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT DO NOTHING
                    """, (
                        metrics.get('cpu_usage', 0),
                        metrics.get('memory_usage', 0),
                        metrics.get('disk_usage', 0),
                        metrics.get('connections', {}).get('total_connections', 0),
                        metrics.get('connections', {}).get('active_connections', 0),
                        metrics.get('connections', {}).get('idle_connections', 0),
                        self._calculate_cost_impact(metrics),
                        f'{database_type}-primary'
                    ))
                
                # Store cost metrics
                cost_metrics = self._calculate_cost_metrics(database_type, metrics)
                for metric_name, metric_value in cost_metrics.items():
                    cursor.execute("""
                        INSERT INTO cost_metrics 
                        (metric_name, metric_value, cost_impact, node_name, database_type)
                        VALUES (%s, %s, %s, %s, %s)
                        ON CONFLICT DO NOTHING
                    """, (metric_name, metric_value, metric_value, f'{database_type}-primary', database_type))
                
                conn.commit()
                cursor.close()
            
            # Store in MongoDB for real-time analytics
            self._store_in_mongodb(database_type, metrics)
            
            # Store in MySQL for real-time analytics
            self._store_in_mysql(database_type, metrics)
            
            # Store in PostgreSQL for real-time analytics
            self._store_in_postgresql(database_type, metrics)
            
            return True
            
        except Exception as e:
            print(f"Error storing metrics: {e}")
            return False
    
    def _store_in_mongodb(self, database_type: str, metrics: Dict[str, Any]) -> bool:
        """Store metrics in MongoDB using real data insertion system"""
        try:
            client = self.connections['mongodb']
            db = client['dbcostops_monitoring']
            
            # Execute real data insertion
            db.eval("""
                if (typeof insertRealMetrics === 'function') {
                    insertRealMetrics('%s', '%s', %s);
                } else {
                    print('Real data insertion system not loaded');
                }
            """ % (f'{database_type}-primary', database_type, str(metrics)))
            
            return True
            
        except Exception as e:
            print(f"Error storing in MongoDB: {e}")
            return False
    
    def _store_in_mysql(self, database_type: str, metrics: Dict[str, Any]) -> bool:
        """Store metrics in MySQL using real data insertion system"""
        try:
            conn = self.connections['mysql']
            cursor = conn.cursor()
            
            # Execute real data insertion procedure
            cursor.callproc('insert_real_metrics', [
                f'{database_type}-primary',
                database_type,
                json.dumps(metrics)
            ])
            
            conn.commit()
            cursor.close()
            
            return True
            
        except Exception as e:
            print(f"Error storing in MySQL: {e}")
            return False
    
    def _store_in_postgresql(self, database_type: str, metrics: Dict[str, Any]) -> bool:
        """Store metrics in PostgreSQL using real data insertion system"""
        try:
            conn = self.connections['postgresql']
            cursor = conn.cursor()
            
            # Execute real data insertion function
            cursor.callproc('insert_real_metrics', [
                f'{database_type}-primary',
                database_type,
                json.dumps(metrics)
            ])
            
            conn.commit()
            cursor.close()
            
            return True
            
        except Exception as e:
            print(f"Error storing in PostgreSQL: {e}")
            return False
    
    def _calculate_cost_impact(self, metrics: Dict[str, Any]) -> float:
        """Calculate cost impact based on metrics"""
        cpu_usage = metrics.get('cpu_usage', 0)
        memory_usage = metrics.get('memory_usage', 0)
        
        # Simple cost calculation based on resource usage
        base_cost = 0.01  # $0.01 per hour base
        cpu_factor = cpu_usage / 100
        memory_factor = memory_usage / 100
        
        return base_cost * (1 + cpu_factor + memory_factor)
    
    def _calculate_cost_metrics(self, database_type: str, metrics: Dict[str, Any]) -> Dict[str, float]:
        """Calculate cost metrics based on database type and usage"""
        cost_result = self.pricing.calculate_monthly_cost(
            database_type=database_type,
            instance_type='db.t3.medium',  # Default instance
            storage_gb=metrics.get('database_size', {}).get('size_bytes', 0) / (1024**3)
        )
        
        if 'error' in cost_result:
            return {'instance_cost': 0, 'storage_cost': 0, 'total_cost': 0}
        
        return {
            'instance_cost': cost_result['compute_cost'],
            'storage_cost': cost_result['storage_cost'],
            'total_cost': cost_result['total_monthly_cost']
        }
    
    def collect_all_metrics(self) -> Dict[str, Any]:
        """Collect metrics from all databases"""
        all_metrics = {}
        
        # Collect from each database
        for db_type in ['postgresql', 'mysql', 'mongodb']:
            try:
                if db_type == 'postgresql':
                    metrics = self.collect_postgresql_metrics()
                elif db_type == 'mysql':
                    metrics = self.collect_mysql_metrics()
                elif db_type == 'mongodb':
                    metrics = self.collect_mongodb_metrics()
                
                if 'error' not in metrics:
                    all_metrics[db_type] = metrics
                    self.store_metrics(db_type, metrics)
                else:
                    print(f"Error collecting {db_type} metrics: {metrics['error']}")
                    
            except Exception as e:
                print(f"Exception collecting {db_type} metrics: {e}")
        
        return all_metrics
    
    def close_connections(self):
        """Close all database connections"""
        for conn in self.connections.values():
            try:
                if hasattr(conn, 'close'):
                    conn.close()
                elif hasattr(conn, 'shutdown'):
                    conn.shutdown()
            except:
                pass

# Example usage
if __name__ == "__main__":
    collector = DatabaseMetricsCollector()
    
    try:
        while True:
            print("Collecting real database metrics...")
            metrics = collector.collect_all_metrics()
            print(f"Collected metrics: {metrics}")
            
            # Wait for 5 minutes before next collection
            time.sleep(300)
            
    except KeyboardInterrupt:
        print("Stopping metrics collection...")
    finally:
        collector.close_connections()
