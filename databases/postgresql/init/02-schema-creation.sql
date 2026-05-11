-- Cost metrics table for tracking database costs
CREATE TABLE IF NOT EXISTS cost_metrics (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4),
    cost_impact DECIMAL(10,2),
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    database_type VARCHAR(50) DEFAULT 'postgresql',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_metric_name CHECK (metric_name IN (
        'instance_cost', 'storage_cost', 'network_cost', 'total_cost', 'backup_cost'
    )),
    CONSTRAINT chk_cost_impact CHECK (cost_impact >= 0),
    CONSTRAINT chk_environment CHECK (environment IN (
        'development', 'staging', 'production'
    ))
);

-- Query performance tracking table
CREATE TABLE IF NOT EXISTS query_performance (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    query_hash VARCHAR(64) NOT NULL,
    query_text TEXT,
    execution_time DECIMAL(10,6),
    rows_examined BIGINT,
    rows_returned BIGINT,
    cost_impact DECIMAL(10,2),
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_execution_time CHECK (execution_time >= 0),
    CONSTRAINT chk_rows_examined CHECK (rows_examined >= 0),
    CONSTRAINT chk_rows_returned CHECK (rows_returned >= 0),
    CONSTRAINT chk_cost_impact_positive CHECK (cost_impact >= 0),
    CONSTRAINT chk_environment_qp CHECK (environment IN (
        'development', 'staging', 'production'
    ))
);

-- Resource usage monitoring table
CREATE TABLE IF NOT EXISTS resource_usage (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cpu_usage DECIMAL(5,2),
    memory_usage DECIMAL(5,2),
    disk_usage DECIMAL(5,2),
    connections INTEGER,
    active_connections INTEGER,
    idle_connections INTEGER,
    cost_impact DECIMAL(10,2),
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
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
    ))
);

-- Optimization recommendations table
CREATE TABLE IF NOT EXISTS optimization_recommendations (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    recommendation_type VARCHAR(100) NOT NULL,
    description TEXT,
    potential_savings VARCHAR(50),
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'pending',
    implemented_at TIMESTAMP WITH TIME ZONE,
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_recommendation_type CHECK (recommendation_type IN (
        'index_cleanup', 'vacuum_optimization', 'memory_tuning', 
        'query_optimization', 'connection_tuning', 'storage_optimization', 'index_optimization'
    )),
    CONSTRAINT chk_priority CHECK (priority IN ('low', 'medium', 'high')),
    CONSTRAINT chk_status CHECK (status IN ('pending', 'in_progress', 'implemented', 'rejected')),
    CONSTRAINT chk_environment_or CHECK (environment IN (
        'development', 'staging', 'production'
    ))
);

-- Backup events tracking table
CREATE TABLE IF NOT EXISTS backup_events (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    event_type VARCHAR(50) NOT NULL,
    backup_file VARCHAR(500),
    backup_size_mb DECIMAL(10,2),
    backup_duration_seconds INTEGER,
    status VARCHAR(50),
    error_message TEXT,
    node_name VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'development',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_event_type CHECK (event_type IN (
        'start', 'complete', 'verify', 'cleanup', 'failed', 'full_backup', 'incremental_backup'
    )),
    CONSTRAINT chk_backup_size CHECK (backup_size_mb >= 0),
    CONSTRAINT chk_backup_duration CHECK (backup_duration_seconds >= 0),
    CONSTRAINT chk_environment_be CHECK (environment IN (
        'development', 'staging', 'production'
    ))
);

-- Cost metrics indexes
CREATE INDEX IF NOT EXISTS idx_cost_metrics_timestamp ON cost_metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_cost_metrics_node_name ON cost_metrics(node_name);
CREATE INDEX IF NOT EXISTS idx_cost_metrics_metric_name ON cost_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_cost_metrics_composite ON cost_metrics(node_name, metric_name, timestamp);

-- Query performance indexes
CREATE INDEX IF NOT EXISTS idx_query_performance_timestamp ON query_performance(timestamp);
CREATE INDEX IF NOT EXISTS idx_query_performance_hash ON query_performance(query_hash);
CREATE INDEX IF NOT EXISTS idx_query_performance_execution_time ON query_performance(execution_time);
CREATE INDEX IF NOT EXISTS idx_query_performance_composite ON query_performance(node_name, timestamp);

-- Resource usage indexes
CREATE INDEX IF NOT EXISTS idx_resource_usage_timestamp ON resource_usage(timestamp);
CREATE INDEX IF NOT EXISTS idx_resource_usage_node_name ON resource_usage(node_name);
CREATE INDEX IF NOT EXISTS idx_resource_usage_composite ON resource_usage(node_name, timestamp);

-- Optimization recommendations indexes
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_timestamp ON optimization_recommendations(timestamp);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_status ON optimization_recommendations(status);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_priority ON optimization_recommendations(priority);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_composite ON optimization_recommendations(node_name, status);

-- Backup events indexes
CREATE INDEX IF NOT EXISTS idx_backup_events_timestamp ON backup_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_backup_events_event_type ON backup_events(event_type);
CREATE INDEX IF NOT EXISTS idx_backup_events_composite ON backup_events(node_name, event_type);

\echo 'PostgreSQL schema creation completed successfully!'
\echo 'Tables created: cost_metrics, query_performance, resource_usage, optimization_recommendations, backup_events'
\echo 'Indexes created for optimal query performance'
