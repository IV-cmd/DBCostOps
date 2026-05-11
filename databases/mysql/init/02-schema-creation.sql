-- Use the monitoring database
USE dbcostops_monitoring;

-- Cost metrics table for tracking database costs
CREATE TABLE IF NOT EXISTS cost_metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4),
    cost_impact DECIMAL(10,2),
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    database_type VARCHAR(50) DEFAULT 'mysql',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_metric_name CHECK (metric_name IN (
        'instance_cost', 'storage_cost', 'network_cost', 'total_cost', 'backup_cost'
    )),
    CONSTRAINT chk_cost_impact CHECK (cost_impact >= 0),
    CONSTRAINT chk_environment CHECK (environment IN (
        'development', 'staging', 'production'
    )),
    
    -- Indexes
    INDEX idx_timestamp (timestamp),
    INDEX idx_node_name (node_name),
    INDEX idx_metric_name (metric_name),
    INDEX idx_composite (node_name, metric_name, timestamp)
);

-- Query performance tracking table
CREATE TABLE IF NOT EXISTS query_performance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    query_hash VARCHAR(64) NOT NULL,
    query_text TEXT,
    execution_time DECIMAL(10,6),
    rows_examined BIGINT,
    rows_returned BIGINT,
    cost_impact DECIMAL(10,2),
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_execution_time CHECK (execution_time >= 0),
    CONSTRAINT chk_rows_examined CHECK (rows_examined >= 0),
    CONSTRAINT chk_rows_returned CHECK (rows_returned >= 0),
    CONSTRAINT chk_cost_impact_positive CHECK (cost_impact >= 0),
    CONSTRAINT chk_environment_qp CHECK (environment IN (
        'development', 'staging', 'production'
    )),
    
    -- Indexes
    INDEX idx_timestamp (timestamp),
    INDEX idx_query_hash (query_hash),
    INDEX idx_execution_time (execution_time),
    INDEX idx_composite_qp (node_name, timestamp)
);

-- Resource usage monitoring table
CREATE TABLE IF NOT EXISTS resource_usage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cpu_usage DECIMAL(5,2),
    memory_usage DECIMAL(5,2),
    disk_usage DECIMAL(5,2),
    connections INT,
    active_connections INT,
    idle_connections INT,
    cost_impact DECIMAL(10,2),
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_cpu_usage CHECK (cpu_usage >= 0 AND cpu_usage <= 100),
    CONSTRAINT chk_memory_usage CHECK (memory_usage >= 0 AND memory_usage <= 100),
    CONSTRAINT chk_disk_usage CHECK (disk_usage >= 0 AND disk_usage <= 100),
    CONSTRAINT chk_connections CHECK (connections >= 0),
    CONSTRAINT chk_active_connections CHECK (active_connections >= 0),
    CONSTRAINT chk_idle_connections CHECK (idle_connections >= 0),
    CONSTRAINT chk_connections_total CHECK (
        active_connections + idle_connections <= connections
    ),
    CONSTRAINT chk_cost_impact_ru CHECK (cost_impact >= 0),
    CONSTRAINT chk_environment_ru CHECK (environment IN (
        'development', 'staging', 'production'
    )),
    
    -- Indexes
    INDEX idx_timestamp (timestamp),
    INDEX idx_node_name (node_name),
    INDEX idx_composite_ru (node_name, timestamp)
);

-- Optimization recommendations table
CREATE TABLE IF NOT EXISTS optimization_recommendations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    recommendation_type VARCHAR(100) NOT NULL,
    description TEXT,
    potential_savings VARCHAR(50),
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'pending',
    implemented_at TIMESTAMP NULL,
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_recommendation_type CHECK (recommendation_type IN (
        'query_optimization', 'buffer_pool_tuning', 'index_optimization',
        'connection_tuning', 'storage_optimization', 'cache_optimization'
    )),
    CONSTRAINT chk_priority CHECK (priority IN ('low', 'medium', 'high')),
    CONSTRAINT chk_status CHECK (status IN ('pending', 'in_progress', 'implemented', 'rejected')),
    CONSTRAINT chk_environment_or CHECK (environment IN (
        'development', 'staging', 'production'
    )),
    
    -- Indexes
    INDEX idx_timestamp (timestamp),
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_composite_or (node_name, status)
);

-- Backup events tracking table
CREATE TABLE IF NOT EXISTS backup_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_type VARCHAR(50) NOT NULL,
    backup_file VARCHAR(500),
    backup_size_mb DECIMAL(10,2),
    backup_duration_seconds INT,
    status VARCHAR(50),
    error_message TEXT,
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_event_type CHECK (event_type IN (
        'start', 'complete', 'verify', 'cleanup', 'failed'
    )),
    CONSTRAINT chk_backup_size CHECK (backup_size_mb >= 0),
    CONSTRAINT chk_backup_duration CHECK (backup_duration_seconds >= 0),
    CONSTRAINT chk_environment_be CHECK (environment IN (
        'development', 'staging', 'production'
    )),
    
    -- Indexes
    INDEX idx_timestamp (timestamp),
    INDEX idx_event_type (event_type),
    INDEX idx_composite_be (node_name, event_type)
);

SELECT 'MySQL schema creation completed successfully!' as status;
SELECT 'Tables created: cost_metrics, query_performance, resource_usage, optimization_recommendations, backup_events' as details;
SELECT 'Indexes created for optimal query performance' as index_info;
