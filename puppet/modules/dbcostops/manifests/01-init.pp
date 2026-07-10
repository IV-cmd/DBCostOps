class dbcostops (
  Boolean $enabled = true,
  String $environment = 'development',
  Boolean $cost_optimization = true,
  Boolean $monitoring_enabled = true,
  Boolean $backup_enabled = true,
  Boolean $security_enabled = false,
  Boolean $compliance_enabled = false,
  Boolean $debug_enabled = false,
  String $log_level = 'info',
  Hash $cost_engine = {},
  Hash $databases = {},
  Hash $monitoring = {},
  Hash $compliance = {},
  Hash $security = {},
  Hash $backup = {},
) {

  if !($environment in ['development', 'staging', 'production', 'testing']) {
    fail("Environment must be one of: development, staging, production, testing")
  }

  if !($log_level in ['debug', 'info', 'warn', 'error', 'fatal']) {
    fail("Log level must be one of: debug, info, warn, error, fatal")
  }

  # CORE COMPONENTS

  # Include base configuration
  contain dbcostops::params
  contain dbcostops::install
  contain dbcostops::config
  contain dbcostops::service

  # OPTIONAL COMPONENTS

  if $cost_optimization {
    contain dbcostops::cost_optimization
  }

  if $monitoring_enabled {
    contain dbcostops::monitoring
  }

  if $backup_enabled {
    contain dbcostops::backup
  }

  if $security_enabled {
    contain dbcostops::security
  }

  if $compliance_enabled {
    contain dbcostops::compliance
  }

  # DEPENDENCY MANAGEMENT

  Class['dbcostops::install'] -> Class['dbcostops::config'] -> Class['dbcostops::service']

  if $cost_optimization {
    Class['dbcostops::config'] -> Class['dbcostops::cost_optimization']
  }

  if $monitoring_enabled {
    Class['dbcostops::config'] -> Class['dbcostops::monitoring']
  }

  if $backup_enabled {
    Class['dbcostops::config'] -> Class['dbcostops::backup']
  }

  if $security_enabled {
    Class['dbcostops::config'] -> Class['dbcostops::security']
  }

  if $compliance_enabled {
    Class['dbcostops::config'] -> Class['dbcostops::compliance']
  }

  # DIRECTORY STRUCTURE

  $config_dirs = [
    '/etc/dbcostops',
    '/etc/dbcostops/conf.d',
    '/etc/dbcostops/certs',
    '/var/log/dbcostops',
    '/var/lib/dbcostops',
    '/var/run/dbcostops',
  ]

  file { $config_dirs:
    ensure => directory,
    owner  => 'dbcostops',
    group  => 'dbcostops',
    mode   => '0755',
    before => Class['dbcostops::install'],
  }

  file { '/etc/dbcostops/logging.yaml':
    ensure  => file,
    owner   => 'dbcostops',
    group   => 'dbcostops',
    mode    => '0644',
    content => template('dbcostops/logging.yaml.erb'),
    notify  => Class['dbcostops::service'],
  }

}
