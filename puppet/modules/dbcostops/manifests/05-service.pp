class dbcostops::service inherits dbcostops::params {

  exec { 'systemd-reload':
    command     => '/usr/bin/systemctl daemon-reload',
    refreshonly => true,
    path        => ['/usr/bin', '/usr/sbin'],
  }

  service { 'dbcostops':
    ensure     => running,
    enable     => true,
    provider   => $dbcostops::params::service_provider,
    subscribe  => [
      File["${dbcostops::params::config_dir}/main.yaml"],
      File["${dbcostops::params::config_dir}/environment.yaml"],
      File["${dbcostops::params::config_dir}/logging.yaml"],
    ],
    require    => [
      Package['dbcostops-core'],
      Exec['systemd-reload'],
    ],
  }

  service { 'dbcostops-api':
    ensure     => running,
    enable     => true,
    provider   => $dbcostops::params::service_provider,
    subscribe  => [
      File["${dbcostops::params::config_dir}/main.yaml"],
      File["${dbcostops::params::config_dir}/environment.yaml"],
    ],
    require    => [
      Package['dbcostops-core'],
      Exec['systemd-reload'],
    ],
  }

  if $dbcostops::monitoring_enabled {
    service { 'dbcostops-monitor':
      ensure     => running,
      enable     => true,
      provider   => $dbcostops::params::service_provider,
      subscribe  => File["${dbcostops::params::config_dir}/monitoring.yaml"],
      require    => [
        Package['dbcostops-core'],
        Exec['systemd-reload'],
      ],
    }
  }

  if $dbcostops::cost_optimization {
    service { 'dbcostops-optimizer':
      ensure     => running,
      enable     => true,
      provider   => $dbcostops::params::service_provider,
      subscribe  => File["${dbcostops::params::config_dir}/cost_optimization.yaml"],
      require    => [
        Package['dbcostops-core'],
        Exec['systemd-reload'],
      ],
    }
  }

  if $dbcostops::backup_enabled {
    service { 'dbcostops-backup':
      ensure     => running,
      enable     => true,
      provider   => $dbcostops::params::service_provider,
      subscribe  => File["${dbcostops::params::config_dir}/backup.yaml"],
      require    => [
        Package['dbcostops-core'],
        Exec['systemd-reload'],
      ],
    }
  }

  file { '/usr/local/bin/dbcostops-health-check':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('dbcostops/health-check.sh.erb'),
    require => Package['dbcostops-core'],
  }

  cron { 'dbcostops-health-check':
    command  => '/usr/local/bin/dbcostops-health-check',
    user     => 'root',
    minute   => '*/5',
    ensure   => present,
    require  => File['/usr/local/bin/dbcostops-health-check'],
  }

  # Ensure main service starts before specialized services
  Service['dbcostops'] -> Service['dbcostops-api']

  if $dbcostops::monitoring_enabled {
    Service['dbcostops'] -> Service['dbcostops-monitor']
  }

  if $dbcostops::cost_optimization {
    Service['dbcostops'] -> Service['dbcostops-optimizer']
  }

  if $dbcostops::backup_enabled {
    Service['dbcostops'] -> Service['dbcostops-backup']
  }

  # Restart services on configuration changes
  File["${dbcostops::params::config_dir}/main.yaml"] ~> Service['dbcostops']
  File["${dbcostops::params::config_dir}/environment.yaml"] ~> Service['dbcostops-api']

  if $dbcostops::monitoring_enabled {
    File["${dbcostops::params::config_dir}/monitoring.yaml"] ~> Service['dbcostops-monitor']
  }

  if $dbcostops::cost_optimization {
    File["${dbcostops::params::config_dir}/cost_optimization.yaml"] ~> Service['dbcostops-optimizer']
  }

  if $dbcostops::backup_enabled {
    File["${dbcostops::params::config_dir}/backup.yaml"] ~> Service['dbcostops-backup']
  }

}
