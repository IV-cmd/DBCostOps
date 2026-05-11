-- Current cost summary view
CREATE OR REPLACE VIEW v_current_cost_summary AS
SELECT 
    node_name,
    SUM(CASE WHEN metric_name = 'total_cost' THEN metric_value ELSE 0 END) as total_cost,
    SUM(CASE WHEN metric_name = 'instance_cost' THEN metric_value ELSE 0 END) as instance_cost,
    SUM(CASE WHEN metric_name = 'storage_cost' THEN metric_value ELSE 0 END) as storage_cost,
    SUM(CASE WHEN metric_name = 'network_cost' THEN metric_value ELSE 0 END) as network_cost,
    MAX(timestamp) as last_updated
FROM cost_metrics 
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY node_name;

-- Optimization summary view
CREATE OR REPLACE VIEW v_optimization_summary AS
SELECT 
    node_name,
    COUNT(*) as total_recommendations,
    COUNT(CASE WHEN priority = 'high' THEN 1 END) as high_priority_count,
    COUNT(CASE WHEN priority = 'medium' THEN 1 END) as medium_priority_count,
    COUNT(CASE WHEN priority = 'low' THEN 1 END) as low_priority_count,
    COUNT(CASE WHEN status = 'implemented' THEN 1 END) as implemented_count,
    MAX(timestamp) as last_recommendation
FROM optimization_recommendations 
WHERE timestamp >= NOW() - INTERVAL '30 days'
GROUP BY node_name;

-- Backup summary view
CREATE OR REPLACE VIEW v_backup_summary AS
SELECT 
    node_name,
    COUNT(CASE WHEN event_type = 'complete' THEN 1 END) as successful_backups,
    COUNT(CASE WHEN event_type = 'start' THEN 1 END) as backup_attempts,
    AVG(backup_duration_seconds) as avg_backup_duration,
    MAX(timestamp) as last_backup,
    MAX(CASE WHEN event_type = 'complete' THEN timestamp END) as last_successful_backup
FROM backup_events 
WHERE timestamp >= NOW() - INTERVAL '30 days'
GROUP BY node_name;

-- Query performance summary view
CREATE OR REPLACE VIEW v_query_performance_summary AS
SELECT 
    node_name,
    COUNT(*) as total_queries,
    AVG(execution_time) as avg_execution_time,
    MAX(execution_time) as max_execution_time,
    SUM(rows_examined) as total_rows_examined,
    SUM(rows_returned) as total_rows_returned,
    SUM(cost_impact) as total_cost_impact,
    MAX(timestamp) as last_query
FROM query_performance 
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY node_name;

-- Resource usage summary view
CREATE OR REPLACE VIEW v_resource_usage_summary AS
SELECT 
    node_name,
    AVG(cpu_usage) as avg_cpu_usage,
    MAX(cpu_usage) as max_cpu_usage,
    AVG(memory_usage) as avg_memory_usage,
    MAX(memory_usage) as max_memory_usage,
    AVG(disk_usage) as avg_disk_usage,
    MAX(connections) as max_connections,
    AVG(active_connections) as avg_active_connections,
    MAX(timestamp) as last_updated
FROM resource_usage 
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY node_name;

-- Cost trends view (last 30 days)
CREATE OR REPLACE VIEW v_cost_trends AS
SELECT 
    DATE_TRUNC('day', timestamp) as date,
    metric_name,
    AVG(metric_value) as daily_avg,
    MAX(metric_value) as daily_max,
    MIN(metric_value) as daily_min,
    node_name
FROM cost_metrics 
WHERE timestamp >= NOW() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', timestamp), metric_name, node_name
ORDER BY date DESC, metric_name;

\echo 'PostgreSQL views creation completed successfully!'
\echo 'Views created: v_current_cost_summary, v_optimization_summary, v_backup_summary, v_query_performance_summary, v_resource_usage_summary, v_cost_trends'
