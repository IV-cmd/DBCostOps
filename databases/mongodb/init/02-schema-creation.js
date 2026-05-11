// Cost metrics collection
db.createCollection('cost_metrics', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['timestamp', 'metric_name', 'metric_value', 'cost_impact', 'node_name'],
      properties: {
        timestamp: { bsonType: 'date' },
        metric_name: { 
          bsonType: 'string',
          enum: ['instance_cost', 'storage_cost', 'network_cost', 'total_cost', 'backup_cost']
        },
        metric_value: { bsonType: 'number', minimum: 0 },
        cost_impact: { bsonType: 'number', minimum: 0 },
        node_name: { bsonType: 'string' },
        environment: { 
          bsonType: 'string',
          enum: ['development', 'staging', 'production']
        },
        database_type: { bsonType: 'string' }
      }
    }
  },
  validationLevel: 'moderate'
});

// Query performance collection
db.createCollection('query_performance', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['timestamp', 'query_hash', 'execution_time', 'rows_examined', 'cost_impact', 'node_name'],
      properties: {
        timestamp: { bsonType: 'date' },
        query_hash: { bsonType: 'string' },
        query_text: { bsonType: 'string' },
        execution_time: { bsonType: 'number', minimum: 0 },
        rows_examined: { bsonType: 'long', minimum: 0 },
        rows_returned: { bsonType: 'long', minimum: 0 },
        cost_impact: { bsonType: 'number', minimum: 0 },
        node_name: { bsonType: 'string' },
        environment: { 
          bsonType: 'string',
          enum: ['development', 'staging', 'production']
        }
      }
    }
  },
  validationLevel: 'moderate'
});

// Resource usage collection
db.createCollection('resource_usage', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['timestamp', 'node_name', 'cpu_usage', 'memory_usage', 'disk_usage', 'connections'],
      properties: {
        timestamp: { bsonType: 'date' },
        node_name: { bsonType: 'string' },
        cpu_usage: { bsonType: 'number', minimum: 0, maximum: 100 },
        memory_usage: { bsonType: 'number', minimum: 0, maximum: 100 },
        disk_usage: { bsonType: 'number', minimum: 0, maximum: 100 },
        connections: { bsonType: 'int', minimum: 0 },
        active_connections: { bsonType: 'int', minimum: 0 },
        idle_connections: { bsonType: 'int', minimum: 0 },
        cost_impact: { bsonType: 'number', minimum: 0 },
        environment: { 
          bsonType: 'string',
          enum: ['development', 'staging', 'production']
        }
      }
    }
  },
  validationLevel: 'moderate'
});

// Optimization recommendations collection
db.createCollection('optimization_recommendations', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['timestamp', 'recommendation_type', 'description', 'potential_savings', 'priority', 'node_name'],
      properties: {
        timestamp: { bsonType: 'date' },
        recommendation_type: { 
          bsonType: 'string',
          enum: ['cache_increase', 'index_optimization', 'connection_pool_tuning', 'storage_optimization']
        },
        description: { bsonType: 'string' },
        potential_savings: { bsonType: 'string' },
        priority: { 
          bsonType: 'string',
          enum: ['low', 'medium', 'high']
        },
        status: { 
          bsonType: 'string',
          enum: ['pending', 'in_progress', 'implemented', 'rejected']
        },
        node_name: { bsonType: 'string' },
        environment: { 
          bsonType: 'string',
          enum: ['development', 'staging', 'production']
        }
      }
    }
  },
  validationLevel: 'moderate'
});

// Backup events collection
db.createCollection('backup_events', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['timestamp', 'event_type', 'node_name'],
      properties: {
        timestamp: { bsonType: 'date' },
        event_type: { 
          bsonType: 'string',
          enum: ['start', 'complete', 'verify', 'cleanup', 'failed']
        },
        backup_file: { bsonType: 'string' },
        backup_size_mb: { bsonType: 'number', minimum: 0 },
        backup_duration_seconds: { bsonType: 'int', minimum: 0 },
        status: { bsonType: 'string' },
        error_message: { bsonType: 'string' },
        node_name: { bsonType: 'string' },
        environment: { 
          bsonType: 'string',
          enum: ['development', 'staging', 'production']
        }
      }
    }
  },
  validationLevel: 'moderate'
});

// Cost metrics indexes
db.cost_metrics.createIndex({ timestamp: 1 });
db.cost_metrics.createIndex({ node_name: 1 });
db.cost_metrics.createIndex({ metric_name: 1 });
db.cost_metrics.createIndex({ node_name: 1, metric_name: 1, timestamp: 1 });

// Query performance indexes
db.query_performance.createIndex({ timestamp: 1 });
db.query_performance.createIndex({ query_hash: 1 });
db.query_performance.createIndex({ execution_time: 1 });
db.query_performance.createIndex({ node_name: 1, timestamp: 1 });

// Resource usage indexes
db.resource_usage.createIndex({ timestamp: 1 });
db.resource_usage.createIndex({ node_name: 1 });
db.resource_usage.createIndex({ node_name: 1, timestamp: 1 });

// Optimization recommendations indexes
db.optimization_recommendations.createIndex({ timestamp: 1 });
db.optimization_recommendations.createIndex({ status: 1 });
db.optimization_recommendations.createIndex({ priority: 1 });
db.optimization_recommendations.createIndex({ node_name: 1, status: 1 });

// Backup events indexes
db.backup_events.createIndex({ timestamp: 1 });
db.backup_events.createIndex({ event_type: 1 });
db.backup_events.createIndex({ node_name: 1, event_type: 1 });

print('MongoDB schema creation completed successfully!');
print('Collections created: cost_metrics, query_performance, resource_usage, optimization_recommendations, backup_events');
print('Indexes created for optimal query performance');
