# DBCostOps - Database DevOps Cost Optimizer

A comprehensive database DevOps platform that automates database infrastructure management, optimizes costs across multiple database engines, and provides GitOps-style database operations with real-time cost analysis and resource optimization.

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Git
- 8GB+ RAM (16GB recommended)
- 4+ CPU cores (8+ recommended)

### Installation

1. **Clone and Setup**
```bash
git clone <repository-url>
cd DBCostOps
```

2. **Start All Services**
```bash
docker-compose up -d
```

3. **Initialize Services**
```bash
# Wait for services to start (2-3 minutes)
# Initialize Puppet environment
docker-compose exec puppet-server puppetserver ca generate

# Initialize databases
docker-compose exec postgres-primary psql -U dbcostops_user -d dbcostops -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
docker-compose exec mysql-primary mysql -u root -proot_password -e "CREATE DATABASE IF NOT EXISTS rundeck;"
docker-compose exec mongodb-primary mongosh --eval "db.getSiblingDB('dbcostops').createCollection('init')"
```

4. **Access Applications**
- **Grafana Dashboard**: http://localhost:3000 (admin/admin123)
- **Kibana Analytics**: http://localhost:5601
- **Rundeck Jobs**: http://localhost:4440 (admin/admin)
- **Puppet Server**: http://localhost:8080
- **Cost Engine API**: http://localhost:8000/docs
- **Prometheus**: http://localhost:9090

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitOps        │    │   Rundeck UI    │    │   ELK Stack     │
│   Repository    │◄──►│  (DevOps Jobs)  │◄──►│ (Cost Analytics)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Puppet Master │    │   Cost Engine   │    │   SQL Optimizer │
│ (Configuration) │◄──►│ (AI Analysis)   │◄──►│ (Query Analysis)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Database Cluster │
                    │ (Multi-Engine)  │
                    └─────────────────┘
```

## 📊 Features

### 🔧 Infrastructure Management
- **Multi-Database Support**: PostgreSQL, MySQL, MongoDB, Redis
- **Puppet Configuration**: Infrastructure as Code for database deployments
- **GitOps Workflows**: Version-controlled database operations
- **Automated Scaling**: Intelligent resource allocation

### 💰 Cost Optimization
- **Real-time Cost Tracking**: Live monitoring of database costs
- **Resource Optimization**: Automated right-sizing recommendations
- **AI-Powered Analysis**: Machine learning for cost prediction
- **Budget Management**: Budget tracking and alerts

### 📈 Monitoring & Analytics
- **ELK Stack**: Advanced log analysis and visualization
- **Prometheus Metrics**: Real-time performance monitoring
- **Grafana Dashboards**: Interactive cost and performance dashboards
- **Custom Analytics**: Tailored insights for database optimization

### 🤖 Automation & DevOps
- **Rundeck Integration**: Automated database lifecycle management
- **Compliance Automation**: Automated compliance checking
- **Backup Management**: Intelligent backup strategies
- **Maintenance Scheduling**: Automated maintenance with cost optimization

## 🛠️ Development Workflow

### 1. Database Configuration (GitOps)
```bash
# Clone configuration repository
git clone ./gitops/dbcostops-configs
cd dbcostops-configs

# Make changes to database configuration
vim databases/postgresql/production.yaml

# Commit and push changes
git add .
git commit -m "Update PostgreSQL configuration"
git push origin main
```

### 2. Cost Analysis
```bash
# Access cost engine API
curl http://localhost:8000/api/v1/cost/current

# Get optimization recommendations
curl http://localhost:8000/api/v1/optimization/recommendations
```

### 3. Monitoring
- **Grafana**: http://localhost:3000 - Cost and performance dashboards
- **Kibana**: http://localhost:5601 - Log analysis and cost analytics
- **Prometheus**: http://localhost:9090 - Raw metrics

### 4. Automation Jobs
- **Rundeck**: http://localhost:4440 - Database operations and maintenance
- **Puppet**: Infrastructure configuration and management

## 📁 Project Structure

```
dbcostops/
├── docker-compose.yml              # Local environment setup
├── puppet/                         # Puppet modules and manifests
│   ├── modules/
│   ├── manifests/
│   └── hieradata/
├── elk-stack/                      # ELK configuration
│   ├── elasticsearch/
│   ├── logstash/
│   └── kibana/
├── databases/                      # Database configurations
│   ├── postgresql/
│   ├── mysql/
│   └── mongodb/
├── cost-engine/                    # Cost optimization engine
│   ├── pricing-api/
│   ├── optimization/
│   └── analytics/
├── rundeck/                        # Rundeck jobs and workflows
├── gitops/                         # Git repository for configs
└── monitoring/                     # Grafana dashboards
```

## 🎯 Demo Scenarios

### 1. Cost Optimization Demo
1. Navigate to Grafana dashboard
2. View current database costs
3. Apply optimization recommendations
4. Monitor cost savings in real-time

### 2. GitOps Database Deployment
1. Modify database configuration in Git repository
2. Submit pull request
3. Automated testing and validation
4. Deploy to production with cost analysis

### 3. Multi-Database Management
1. View cost across PostgreSQL, MySQL, MongoDB
2. Compare performance vs cost ratios
3. Optimize resource allocation
4. Generate compliance reports

### 4. Automated Recovery
1. Simulate database failure
2. Watch automated recovery process
3. Monitor cost impact of recovery actions
4. Generate incident reports

## 🔧 Configuration

### Environment Variables
```bash
# Database Configuration
DATABASE_URL=postgresql://dbcostops_user:dbcostops_password@postgres-primary:5432/dbcostops

# Cost Engine Configuration
COST_ENGINE_REFRESH_INTERVAL=30
OPTIMIZATION_ENABLED=true
BUDGET_ALERTS_ENABLED=true

# Monitoring Configuration
PROMETHEUS_RETENTION=200h
ELASTICSEARCH_RETENTION=30d
```

### Puppet Configuration
```yaml
# puppet/hieradata/common.yaml
databases:
  postgresql:
    version: "15"
    max_connections: 100
    shared_buffers: "256MB"
    cost_optimization: true
  
  mysql:
    version: "8.0"
    max_connections: 150
    innodb_buffer_pool_size: "512MB"
    cost_optimization: true
```

## 📊 Cost Simulation

The system includes realistic cost simulation for:
- **AWS RDS**: PostgreSQL, MySQL, MongoDB pricing
- **AWS ElastiCache**: Redis pricing
- **Storage Costs**: EBS storage pricing
- **Network Costs**: Data transfer pricing
- **Compute Costs**: EC2 instance pricing

## 🚨 Alerts & Notifications

### Cost Alerts
- Budget threshold alerts
- Anomaly detection
- Optimization opportunities
- Cost trend analysis

### Performance Alerts
- Database performance degradation
- Resource utilization warnings
- Query performance issues
- Replication lag alerts

## 🔒 Security Features

- **Role-Based Access**: Granular permissions for different user types
- **Audit Logging**: Complete audit trail of all operations
- **Compliance Checks**: Automated compliance validation
- **Data Encryption**: Encrypted data at rest and in transit

## 📈 Performance Metrics

- **Database Performance**: Query performance, connection metrics
- **Cost Metrics**: Real-time cost tracking and optimization
- **Resource Utilization**: CPU, memory, storage usage
- **Compliance Metrics**: Compliance score and remediation

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Submit pull request with cost analysis

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

For support and questions:
- Check documentation in `/docs`
- Review Grafana dashboards for troubleshooting
- Check Rundeck job logs for automation issues
- Review ELK logs for detailed analysis
