-- Step 1: Database and user setup
\ir 01-database-setup.sql

-- Step 2: Schema creation (tables, indexes, constraints)
\ir 02-schema-creation.sql

-- Step 3: Views creation for analytics
\ir 03-views-creation.sql

-- Step 4: Real data collection system
\ir 04-real-data-insertion.sql

\echo ''
\echo 'PostgreSQL DBCostOps initialization completed!'
\echo 'Database: dbcostops_monitoring'
\echo 'User: dbcostops_monitor'
\echo 'Tables: 5 (cost_metrics, query_performance, resource_usage, optimization_recommendations, backup_events)'
\echo 'Views: 6 (v_current_cost_summary, v_optimization_summary, v_backup_summary, v_query_performance_summary, v_resource_usage_summary, v_cost_trends)'
\echo 'Real data collection system: Ready for live metrics insertion'
