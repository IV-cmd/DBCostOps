# DBCostOps Monitoring Stack

This directory contains the complete monitoring infrastructure for DBCostOps, including Prometheus metrics collection, Grafana visualization, and comprehensive alerting.

## Structure

The monitoring stack follows a modular, clean architecture:

```
monitoring/
├── prometheus/
│   └── config/
│       ├── 00-master-config.yml          # Master configuration file
│       ├── 01-global-settings.yml        # Global settings and server config
│       ├── 02-scrape-configs.yml        # All scrape jobs and targets
│       └── 03-alerting-rules.yml       # Comprehensive alerting rules
├── grafana/
│   └── config/
│       ├── 00-master-config.yml          # Master configuration file
│       ├── 01-server-settings.yml        # Server and authentication settings
│       ├── 02-datasources.yml          # All data sources configuration
│       └── 03-dashboard-settings.yml    # Dashboard provisioning and alerts
│   └── dashboards/
│       ├── 01-cost-overview-dashboard.json     # Cost analysis dashboard
│       ├── 02-performance-dashboard.json       # Performance monitoring
│       ├── 03-optimization-dashboard.json     # Optimization recommendations
│       ├── 04-backup-dashboard.json          # Backup monitoring
│       └── 05-alerts-dashboard.json         # Alert management
```

## Components

### Prometheus

**Purpose**: Metrics collection and alerting engine

**Configuration Modules**:
- **Global Settings**: Server configuration, evaluation intervals, external labels
- **Scrape Configs**: 10 different scrape jobs for all services
- **Alerting Rules**: 5 rule groups with comprehensive coverage

**Scrape Targets**:
- Prometheus self-monitoring (port 9090)
- PostgreSQL Exporter (port 9187)
- MySQL Exporter (port 9104)
- MongoDB Exporter (port 9216)
- Node Exporter (port 9100)
- DBCostOps Cost Engine API (port 8000)
- Redis Exporter (port 9121)
- Elasticsearch Exporter (port 9114)
- Custom DBCostOps Metrics (port 8080)
- Docker Container Metrics (port 9323)

**Alerting Rule Groups**:
- **Cost Alerts**: High/critical total cost, storage cost thresholds
- **Performance Alerts**: CPU, memory, disk usage monitoring
- **Query Alerts**: Slow queries, high query cost impact
- **Backup Alerts**: Backup failures, backup age monitoring
- **Optimization Alerts**: High priority recommendations, optimization tracking

### Grafana

**Purpose**: Data visualization and dashboard management

**Configuration Modules**:
- **Server Settings**: Authentication, database, logging configuration
- **Datasources**: 5 datasources (Prometheus, Elasticsearch, PostgreSQL, MySQL, MongoDB)
- **Dashboard Settings**: Provisioning, alerting, notifications

**Dashboard Suite**:
1. **Cost Overview**: Total costs, breakdown, trends, optimization potential
2. **Performance**: CPU, memory, disk usage, connections, query performance
3. **Optimization**: Recommendations, priority breakdown, potential savings
4. **Backup**: Status monitoring, size trends, duration analysis
5. **Alerts**: Active alerts, severity breakdown, alert history

## First-Principles Applied

### Separation of Concerns
- Prometheus: Global settings, scrape configs, alerting rules separated
- Grafana: Server config, datasources, dashboards separated
- Each dashboard focuses on specific monitoring aspect

### Modularity
- Each configuration file independently manageable
- Easy to enable/disable specific monitoring components
- Simple to add new services or modify existing ones

### Consistency
- Same naming conventions across all components
- Consistent metric naming (dbcostops_* prefix)
- Unified dashboard structure and styling

### Performance Optimization
- Optimized scrape intervals for different metrics
- Efficient dashboard queries with proper time ranges
- Strategic alerting thresholds to avoid noise

## Usage

### Quick Start

```bash
# Start Prometheus with master configuration
prometheus --config.file=/etc/prometheus/00-master-config.yml

# Start Grafana with master configuration  
grafana server --config=/etc/grafana/00-master-config.yml
```

### Docker Integration

```yaml
# Prometheus
volumes:
  - ./monitoring/prometheus/config:/etc/prometheus

# Grafana
volumes:
  - ./monitoring/grafana/config:/etc/grafana
  - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
```

## Metrics Reference

### Cost Metrics
- `dbcostops_total_cost` - Total database cost
- `dbcostops_storage_cost` - Storage-related costs
- `dbcostops_instance_cost` - Compute instance costs
- `dbcostops_network_cost` - Network transfer costs

### Performance Metrics
- `dbcostops_cpu_usage` - CPU utilization percentage
- `dbcostops_memory_usage` - Memory utilization percentage
- `dbcostops_disk_usage` - Disk utilization percentage
- `dbcostops_connections` - Total database connections
- `dbcostops_active_connections` - Active connections

### Query Metrics
- `dbcostops_query_execution_time` - Query execution time in seconds
- `dbcostops_query_cost_impact` - Cost impact of queries
- `dbcostops_rows_examined` - Rows examined by queries
- `dbcostops_rows_returned` - Rows returned by queries

### Optimization Metrics
- `dbcostops_optimization_recommendations` - Number of recommendations
- `dbcostops_optimization_potential_savings` - Potential savings percentage
- `dbcostops_optimization_last_implemented_timestamp` - Last optimization time

### Backup Metrics
- `dbcostops_backup_status` - Backup operation status
- `dbcostops_backup_size_mb` - Backup size in megabytes
- `dbcostops_backup_duration_seconds` - Backup duration
- `dbcostops_backup_last_success_timestamp` - Last successful backup

## Alerting

### Alert Severities
- **Info**: Informational alerts (e.g., no recent optimizations)
- **Warning**: Performance issues requiring attention
- **Critical**: Immediate action required (e.g., backup failures, high costs)

### Notification Channels
- SMTP email notifications configured
- AlertManager integration for advanced routing
- Grafana alerting for dashboard-specific alerts

## Security Considerations

### Development Configuration
- Authentication disabled for ease of use
- Default passwords for local development
- No SSL/TLS encryption

### Production Deployment
- Enable authentication and authorization
- Configure SSL/TLS certificates
- Use secure passwords from secrets management
- Implement proper network security

## Troubleshooting

### Common Issues
1. **Prometheus not scraping targets**: Check network connectivity and port accessibility
2. **Grafana dashboards not loading**: Verify datasource configuration
3. **Alerts not firing**: Check alert rule syntax and evaluation intervals
4. **High memory usage**: Adjust scrape intervals and retention periods

### Debug Commands
```bash
# Check Prometheus configuration
promtool check config /etc/prometheus/00-master-config.yml

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Grafana datasources
curl http://admin:admin123@localhost:3000/api/datasources
```

## Scaling Considerations

### Horizontal Scaling
- Multiple Prometheus instances for high availability
- Grafana clustering for large deployments
- Load balancer configuration for high traffic

### Performance Tuning
- Adjust scrape intervals based on metric volatility
- Optimize storage retention and compaction
- Configure appropriate resource limits

## Integration Points

### ELK Stack Integration
- Prometheus metrics forwarded to Elasticsearch
- Unified logging and monitoring in Kibana
- Correlated alerts and log analysis

### Database Integration
- Direct database access for detailed analysis
- Real-time cost calculations from database queries
- Historical trend analysis from stored metrics

## Support

For monitoring issues:
1. Check component-specific logs
2. Verify network connectivity between services
3. Validate configuration syntax
4. Review alert rule performance
5. Monitor resource usage of monitoring components
