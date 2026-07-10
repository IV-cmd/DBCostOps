node /^monitoring-.*$/ {
  include dbcostops::base
  include dbcostops::monitoring::server
  include dbcostops::elk
  include dbcostops::grafana
  include dbcostops::prometheus
  
  if $dbcostops::security_enabled {
    include dbcostops::security::monitoring
  }
}

node 'puppet-server' {
  include dbcostops::base
  include dbcostops::puppet::server
  include dbcostops::puppet::console
  
  if $dbcostops::monitoring_enabled {
    include dbcostops::monitoring::puppet
  }
}

node /^rundeck-.*$/ {
  include dbcostops::base
  include dbcostops::rundeck
  include dbcostops::rundeck::jobs
  
  if $dbcostops::monitoring_enabled {
    include dbcostops::monitoring::rundeck
  }
  
  if $dbcostops::security_enabled {
    include dbcostops::security::rundeck
  }
}

node /^cost-engine-.*$/ {
  include dbcostops::base
  include dbcostops::cost_engine
  include dbcostops::cost_engine::api
  include dbcostops::cost_engine::analytics
  
  if $dbcostops::monitoring_enabled {
    include dbcostops::monitoring::cost_engine
  }
  
  if $dbcostops::security_enabled {
    include dbcostops::security::cost_engine
  }
}

node /^backup-server-.*$/ {
  include dbcostops::base
  include dbcostops::backup::server
  include dbcostops::backup::storage
  
  if $dbcostops::monitoring_enabled {
    include dbcostops::monitoring::backup
  }
  
  if $dbcostops::security_enabled {
    include dbcostops::security::backup
  }
}
