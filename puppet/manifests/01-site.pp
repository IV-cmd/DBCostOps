# Import Hiera data and apply configurations
lookup('classes', { 'merge' => 'unique', 'default_value' => [] }).include

node default {
  # Base configuration for all nodes
  include dbcostops::base
  
  # Include optional components based on Hiera configuration
  if $dbcostops::monitoring_enabled {
    include dbcostops::monitoring
  }
  
  if $dbcostops::cost_optimization {
    include dbcostops::cost_optimization
  }
  
  if $dbcostops::backup_enabled {
    include dbcostops::backup
  }
  
  if $dbcostops::security_enabled {
    include dbcostops::security
  }
}
