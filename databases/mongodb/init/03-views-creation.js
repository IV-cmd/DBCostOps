const now = new Date();
const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

// Current cost summary view
db.createView('v_current_cost_summary', 'cost_metrics', [
  {
    $match: {
      timestamp: { $gte: sevenDaysAgo }
    }
  },
  {
    $group: {
      _id: '$node_name',
      node_name: { $first: '$node_name' },
      total_cost: {
        $sum: {
          $cond: [
            { $eq: ['$metric_name', 'total_cost'] },
            '$metric_value',
            0
          ]
        }
      },
      instance_cost: {
        $sum: {
          $cond: [
            { $eq: ['$metric_name', 'instance_cost'] },
            '$metric_value',
            0
          ]
        }
      },
      storage_cost: {
        $sum: {
          $cond: [
            { $eq: ['$metric_name', 'storage_cost'] },
            '$metric_value',
            0
          ]
        }
      },
      network_cost: {
        $sum: {
          $cond: [
            { $eq: ['$metric_name', 'network_cost'] },
            '$metric_value',
            0
          ]
        }
      },
      last_updated: { $max: '$timestamp' }
    }
  },
  {
    $project: {
      _id: 0,
      node_name: 1,
      total_cost: 1,
      instance_cost: 1,
      storage_cost: 1,
      network_cost: 1,
      last_updated: 1
    }
  }
]);

// Optimization summary view
db.createView('v_optimization_summary', 'optimization_recommendations', [
  {
    $match: {
      timestamp: { $gte: thirtyDaysAgo }
    }
  },
  {
    $group: {
      _id: '$node_name',
      node_name: { $first: '$node_name' },
      total_recommendations: { $sum: 1 },
      high_priority_count: {
        $sum: {
          $cond: [
            { $eq: ['$priority', 'high'] },
            1,
            0
          ]
        }
      },
      medium_priority_count: {
        $sum: {
          $cond: [
            { $eq: ['$priority', 'medium'] },
            1,
            0
          ]
        }
      },
      low_priority_count: {
        $sum: {
          $cond: [
            { $eq: ['$priority', 'low'] },
            1,
            0
          ]
        }
      },
      implemented_count: {
        $sum: {
          $cond: [
            { $eq: ['$status', 'implemented'] },
            1,
            0
          ]
        }
      },
      last_recommendation: { $max: '$timestamp' }
    }
  },
  {
    $project: {
      _id: 0,
      node_name: 1,
      total_recommendations: 1,
      high_priority_count: 1,
      medium_priority_count: 1,
      low_priority_count: 1,
      implemented_count: 1,
      last_recommendation: 1
    }
  }
]);

// Backup summary view
db.createView('v_backup_summary', 'backup_events', [
  {
    $match: {
      timestamp: { $gte: thirtyDaysAgo }
    }
  },
  {
    $group: {
      _id: '$node_name',
      node_name: { $first: '$node_name' },
      successful_backups: {
        $sum: {
          $cond: [
            { $eq: ['$event_type', 'complete'] },
            1,
            0
          ]
        }
      },
      backup_attempts: {
        $sum: {
          $cond: [
            { $eq: ['$event_type', 'start'] },
            1,
            0
          ]
        }
      },
      avg_backup_duration: { $avg: '$backup_duration_seconds' },
      last_backup: { $max: '$timestamp' },
      last_successful_backup: {
        $max: {
          $cond: [
            { $eq: ['$event_type', 'complete'] },
            '$timestamp',
            null
          ]
        }
      }
    }
  },
  {
    $project: {
      _id: 0,
      node_name: 1,
      successful_backups: 1,
      backup_attempts: 1,
      avg_backup_duration: 1,
      last_backup: 1,
      last_successful_backup: 1
    }
  }
]);

// Query performance summary view
db.createView('v_query_performance_summary', 'query_performance', [
  {
    $match: {
      timestamp: { $gte: sevenDaysAgo }
    }
  },
  {
    $group: {
      _id: '$node_name',
      node_name: { $first: '$node_name' },
      total_queries: { $sum: 1 },
      avg_execution_time: { $avg: '$execution_time' },
      max_execution_time: { $max: '$execution_time' },
      total_rows_examined: { $sum: '$rows_examined' },
      total_rows_returned: { $sum: '$rows_returned' },
      total_cost_impact: { $sum: '$cost_impact' },
      last_query: { $max: '$timestamp' }
    }
  },
  {
    $project: {
      _id: 0,
      node_name: 1,
      total_queries: 1,
      avg_execution_time: 1,
      max_execution_time: 1,
      total_rows_examined: 1,
      total_rows_returned: 1,
      total_cost_impact: 1,
      last_query: 1
    }
  }
]);

// Resource usage summary view
db.createView('v_resource_usage_summary', 'resource_usage', [
  {
    $match: {
      timestamp: { $gte: sevenDaysAgo }
    }
  },
  {
    $group: {
      _id: '$node_name',
      node_name: { $first: '$node_name' },
      avg_cpu_usage: { $avg: '$cpu_usage' },
      max_cpu_usage: { $max: '$cpu_usage' },
      avg_memory_usage: { $avg: '$memory_usage' },
      max_memory_usage: { $max: '$memory_usage' },
      avg_disk_usage: { $avg: '$disk_usage' },
      max_connections: { $max: '$connections' },
      avg_active_connections: { $avg: '$active_connections' },
      last_updated: { $max: '$timestamp' }
    }
  },
  {
    $project: {
      _id: 0,
      node_name: 1,
      avg_cpu_usage: 1,
      max_cpu_usage: 1,
      avg_memory_usage: 1,
      max_memory_usage: 1,
      avg_disk_usage: 1,
      max_connections: 1,
      avg_active_connections: 1,
      last_updated: 1
    }
  }
]);

// Cost trends view (last 30 days)
db.createView('v_cost_trends', 'cost_metrics', [
  {
    $match: {
      timestamp: { $gte: thirtyDaysAgo }
    }
  },
  {
    $group: {
      _id: {
        date: { $dateToString: { format: '%Y-%m-%d', date: '$timestamp' } },
        metric_name: '$metric_name',
        node_name: '$node_name'
      },
      date: { $first: { $dateToString: { format: '%Y-%m-%d', date: '$timestamp' } } },
      metric_name: { $first: '$metric_name' },
      node_name: { $first: '$node_name' },
      daily_avg: { $avg: '$metric_value' },
      daily_max: { $max: '$metric_value' },
      daily_min: { $min: '$metric_value' }
    }
  },
  {
    $project: {
      _id: 0,
      date: 1,
      metric_name: 1,
      node_name: 1,
      daily_avg: 1,
      daily_max: 1,
      daily_min: 1
    }
  },
  {
    $sort: { date: -1, metric_name: 1 }
  }
]);

print('MongoDB views creation completed successfully!');
print('Views created: v_current_cost_summary, v_optimization_summary, v_backup_summary, v_query_performance_summary, v_resource_usage_summary, v_cost_trends');
