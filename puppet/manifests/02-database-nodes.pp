node /^postgres-.*$/ {
  include dbcostops::base
  include dbcostops::postgresql
  include dbcostops::monitoring::postgresql
  include dbcostops::backup::postgresql
  
  if $dbcostops::cost_optimization {
    include dbcostops::cost_optimization::postgresql
  }
  
  if $dbcostops::security_enabled {
    include dbcostops::security::postgresql
  }
}

node /^mysql-.*$/ {
  include dbcostops::base
  include dbcostops::mysql
  include dbcostops::monitoring::mysql
  include dbcostops::backup::mysql
  
  if $dbcostops::cost_optimization {
    include dbcostops::cost_optimization::mysql
  }
  
  if $dbcostops::security_enabled {
    include dbcostops::security::mysql
  }
}

node /^mongodb-.*$/ {
  include dbcostops::base
  include dbcostops::mongodb
  include dbcostops::monitoring::mongodb
  include dbcostops::backup::mongodb
  
  if $dbcostops::cost_optimization {
    include dbcostops::cost_optimization::mongodb
  }
  
  if $dbcostops::security_enabled {
    include dbcostops::security::mongodb
  }
}

