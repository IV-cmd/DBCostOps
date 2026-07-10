class dbcostops::params {

  case $facts['os']['family'] {
    'RedHat': {
      $package_provider = 'yum'
      $service_provider = 'systemd'
      $config_dir = '/etc/dbcostops'
      $log_dir = '/var/log/dbcostops'
      $data_dir = '/var/lib/dbcostops'
      $run_dir = '/var/run/dbcostops'
      $user = 'dbcostops'
      $group = 'dbcostops'
      $shell = '/bin/bash'
      $home = '/home/dbcostops'
    }
    'Debian': {
      $package_provider = 'apt'
      $service_provider = 'systemd'
      $config_dir = '/etc/dbcostops'
      $log_dir = '/var/log/dbcostops'
      $data_dir = '/var/lib/dbcostops'
      $run_dir = '/var/run/dbcostops'
      $user = 'dbcostops'
      $group = 'dbcostops'
      $shell = '/bin/bash'
      $home = '/home/dbcostops'
    }
    default: {
      fail("Unsupported operating system family: ${facts['os']['family']}")
    }
  }

  $default_config = {
    'api' => {
      'port' => 8000,
      'host' => '0.0.0.0',
      'workers' => 4,
      'timeout' => 30,
    },
    'database' => {
      'connection_timeout' => 30,
      'query_timeout' => 60,
      'max_connections' => 100,
    },
    'monitoring' => {
      'interval' => 30,
      'retention_days' => 30,
      'metrics_enabled' => true,
    },
    'cost_optimization' => {
      'enabled' => true,
      'budget_alerts' => true,
      'monthly_budget' => 1000.00,
      'optimization_interval' => 3600,
    },
    'backup' => {
      'enabled' => true,
      'schedule' => 'daily',
      'retention_days' => 7,
      'compression' => true,
      'encryption' => true,
    },
    'security' => {
      'ssl_enabled' => false,
      'cert_management' => 'self_signed',
      'firewall_enabled' => false,
    },
    'logging' => {
      'level' => 'info',
      'format' => 'json',
      'rotation' => 'daily',
      'max_size' => '100MB',
    },
  }

  $package_versions = {
    'postgresql' => {
      'RedHat' => '15',
      'Debian' => '15',
    },
    'mysql' => {
      'RedHat' => '8.0',
      'Debian' => '8.0',
    },
    'mongodb' => {
      'RedHat' => '7.0',
      'Debian' => '7.0',
    },
      }

  $service_config = {
    'postgresql' => {
      'port' => 5432,
      'data_dir' => '/var/lib/postgresql/data',
      'config_file' => '/etc/postgresql/postgresql.conf',
      'service_name' => 'postgresql',
    },
    'mysql' => {
      'port' => 3306,
      'data_dir' => '/var/lib/mysql',
      'config_file' => '/etc/mysql/my.cnf',
      'service_name' => 'mysql',
    },
    'mongodb' => {
      'port' => 27017,
      'data_dir' => '/var/lib/mongodb',
      'config_file' => '/etc/mongodb/mongod.conf',
      'service_name' => 'mongod',
    },
      }

  $ports = {
    'api' => 8000,
    'postgresql' => 5432,
    'mysql' => 3306,
    'mongodb' => 27017,
        'prometheus' => 9090,
    'grafana' => 3000,
    'elasticsearch' => 9200,
    'kibana' => 5601,
    'logstash' => 5044,
    'puppet_server' => 8140,
    'rundeck' => 4440,
  }

  # FIREWALL RULES

  $firewall_rules = {
    'postgresql' => {
      'port' => 5432,
      'proto' => 'tcp',
      'action' => 'accept',
      'source' => '10.0.0.0/8',
    },
    'mysql' => {
      'port' => 3306,
      'proto' => 'tcp',
      'action' => 'accept',
      'source' => '10.0.0.0/8',
    },
    'mongodb' => {
      'port' => 27017,
      'proto' => 'tcp',
      'action' => 'accept',
      'source' => '10.0.0.0/8',
    },
        'api' => {
      'port' => 8000,
      'proto' => 'tcp',
      'action' => 'accept',
      'source' => '0.0.0.0/0',
    },
  }

}
