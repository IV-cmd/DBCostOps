-- Step 1: Database and user setup
SOURCE 01-database-setup.sql;

-- Step 2: Schema creation (tables, indexes, constraints)
SOURCE 02-schema-creation.sql;

-- Step 3: Views creation for analytics
SOURCE 03-views-creation.sql;

-- Step 4: Real data collection system
SOURCE 04-real-data-insertion-simple.sql;

SELECT '' as separator;
SELECT 'MySQL DBCostOps initialization completed!' as status;
SELECT 'Database: dbcostops_monitoring' as database_info;
SELECT 'User: dbcostops_monitor' as user_info;
SELECT 'Tables: 5 (cost_metrics, query_performance, resource_usage, optimization_recommendations, backup_events)' as tables_info;
SELECT 'Views: 6 (v_current_cost_summary, v_optimization_summary, v_backup_summary, v_query_performance_summary, v_resource_usage_summary, v_cost_trends)' as views_info;
SELECT 'Real data collection system: Ready for live metrics insertion' as sample_info;
