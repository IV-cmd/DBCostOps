print('Starting MongoDB DBCostOps initialization...');

// Step 1: Database and user setup
print('\n=== Step 1: Database and User Setup ===');
load('01-database-setup.js');

// Step 2: Schema creation (collections, indexes, validation)
print('\n=== Step 2: Schema Creation ===');
load('02-schema-creation.js');

// Step 3: Views creation for analytics
print('\n=== Step 3: Views Creation ===');
load('03-views-creation.js');

// Step 4: Real data collection system
print('\n=== Step 4: Real Data Collection System ===');
load('04-real-data-insertion.js');

print('MongoDB DBCostOps initialization completed!');
print('Database: dbcostops_monitoring');
print('User: dbcostops_monitor');
print('Collections: 5 (cost_metrics, query_performance, resource_usage, optimization_recommendations, backup_events)');
print('Views: 6 (v_current_cost_summary, v_optimization_summary, v_backup_summary, v_query_performance_summary, v_resource_usage_summary, v_cost_trends)');
print('Real data collection system: Ready for live metrics insertion');
