# DEVELOPMENT ENVIRONMENT

node /^.*-dev-.*$/ {
  # environment, debug_enabled, log_level overrides must be set via Hiera node data
  include dbcostops::environment::development
  
  # Development-specific overrides
  if $dbcostops::monitoring_enabled {
    include dbcostops::monitoring::development
  }
  
  if $dbcostops::cost_optimization {
    include dbcostops::cost_optimization::development
  }
}

# STAGING ENVIRONMENT

node /^.*-staging-.*$/ {
  include dbcostops::environment::staging
  
  # Staging-specific configurations
  if $dbcostops::monitoring_enabled {
    include dbcostops::monitoring::staging
  }
  
  if $dbcostops::cost_optimization {
    include dbcostops::cost_optimization::staging
  }
  
  if $dbcostops::security_enabled {
    include dbcostops::security::staging
  }
}

# PRODUCTION ENVIRONMENT

node /^.*-prod-.*$/ {
  include dbcostops::environment::production
  
  # Production-specific requirements
  if $dbcostops::monitoring_enabled {
    include dbcostops::monitoring::production
  }
  
  if $dbcostops::cost_optimization {
    include dbcostops::cost_optimization::production
  }
  
  if $dbcostops::security_enabled {
    include dbcostops::security::production
  }
  
  # Production compliance requirements
  if $dbcostops::compliance_enabled {
    include dbcostops::compliance::production
  }
}

# TESTING ENVIRONMENT

node /^.*-test-.*$/ {
  include dbcostops::environment::testing
  
  # Testing-specific configurations
  if $dbcostops::monitoring_enabled {
    include dbcostops::monitoring::testing
  }
  
  # Test data and fixtures
  include dbcostops::testing::fixtures
  include dbcostops::testing::mock_services
}
