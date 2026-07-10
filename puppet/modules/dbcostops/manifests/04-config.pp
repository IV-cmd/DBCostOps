class dbcostops::config inherits dbcostops::params {

  file { "${dbcostops::params::config_dir}/main.yaml":
    ensure  => file,
    owner   => $dbcostops::params::user,
    group   => $dbcostops::params::group,
    mode    => '0644',
    content => template('dbcostops/main.yaml.erb'),
    notify  => Class['dbcostops::service'],
  }

  # DATABASE CONFIGURATIONS

  # PostgreSQL configuration
  if $dbcostops::databases['postgresql'] {
    file { "${dbcostops::params::config_dir}/postgresql.yaml":
      ensure  => file,
      owner   => $dbcostops::params::user,
      group   => $dbcostops::params::group,
      mode    => '0644',
      content => template('dbcostops/postgresql.yaml.erb'),
      notify  => Class['dbcostops::service'],
    }
  }

  # MySQL configuration
  if $dbcostops::databases['mysql'] {
    file { "${dbcostops::params::config_dir}/mysql.yaml":
      ensure  => file,
      owner   => $dbcostops::params::user,
      group   => $dbcostops::params::group,
      mode    => '0644',
      content => template('dbcostops/mysql.yaml.erb'),
      notify  => Class['dbcostops::service'],
    }
  }

  # MongoDB configuration
  if $dbcostops::databases['mongodb'] {
    file { "${dbcostops::params::config_dir}/mongodb.yaml":
      ensure  => file,
      owner   => $dbcostops::params::user,
      group   => $dbcostops::params::group,
      mode    => '0644',
      content => template('dbcostops/mongodb.yaml.erb'),
      notify  => Class['dbcostops::service'],
    }
  }

  
  if $dbcostops::monitoring_enabled {
    file { "${dbcostops::params::config_dir}/monitoring.yaml":
      ensure  => file,
      owner   => $dbcostops::params::user,
      group   => $dbcostops::params::group,
      mode    => '0644',
      content => template('dbcostops/monitoring.yaml.erb'),
      notify  => Class['dbcostops::service'],
    }
  }

  if $dbcostops::cost_optimization {
    file { "${dbcostops::params::config_dir}/cost_optimization.yaml":
      ensure  => file,
      owner   => $dbcostops::params::user,
      group   => $dbcostops::params::group,
      mode    => '0644',
      content => template('dbcostops/cost_optimization.yaml.erb'),
      notify  => Class['dbcostops::service'],
    }
  }

  if $dbcostops::backup_enabled {
    file { "${dbcostops::params::config_dir}/backup.yaml":
      ensure  => file,
      owner   => $dbcostops::params::user,
      group   => $dbcostops::params::group,
      mode    => '0644',
      content => template('dbcostops/backup.yaml.erb'),
      notify  => Class['dbcostops::service'],
    }
  }

  if $dbcostops::security_enabled {
    file { "${dbcostops::params::config_dir}/security.yaml":
      ensure  => file,
      owner   => $dbcostops::params::user,
      group   => $dbcostops::params::group,
      mode    => '0644',
      content => template('dbcostops/security.yaml.erb'),
      notify  => Class['dbcostops::service'],
    }
  }

  if $dbcostops::compliance_enabled {
    file { "${dbcostops::params::config_dir}/compliance.yaml":
      ensure  => file,
      owner   => $dbcostops::params::user,
      group   => $dbcostops::params::group,
      mode    => '0644',
      content => template('dbcostops/compliance.yaml.erb'),
      notify  => Class['dbcostops::service'],
    }
  }

  file { "${dbcostops::params::config_dir}/environment.yaml":
    ensure  => file,
    owner   => $dbcostops::params::user,
    group   => $dbcostops::params::group,
    mode    => '0644',
    content => template('dbcostops/environment.yaml.erb'),
    notify  => Class['dbcostops::service'],
  }

  file { "${dbcostops::params::config_dir}/logging.yaml":
    ensure  => file,
    owner   => $dbcostops::params::user,
    group   => $dbcostops::params::group,
    mode    => '0644',
    content => template('dbcostops/logging.yaml.erb'),
    notify  => Class['dbcostops::service'],
  }

  if $dbcostops::security_enabled and $dbcostops::security['ssl_enabled'] {
    file { "${dbcostops::params::config_dir}/certs":
      ensure => directory,
      owner  => $dbcostops::params::user,
      group  => $dbcostops::params::group,
      mode   => '0755',
    }

    file { "${dbcostops::params::config_dir}/certs/ssl.conf":
      ensure  => file,
      owner   => $dbcostops::params::user,
      group   => $dbcostops::params::group,
      mode    => '0644',
      content => template('dbcostops/ssl.conf.erb'),
      notify  => Class['dbcostops::service'],
    }
  }

  file { "${dbcostops::params::config_dir}/scripts":
    ensure => directory,
    owner  => $dbcostops::params::user,
    group  => $dbcostops::params::group,
    mode   => '0755',
  }

  file { "${dbcostops::params::config_dir}/scripts/startup.sh":
    ensure  => file,
    owner   => $dbcostops::params::user,
    group   => $dbcostops::params::group,
    mode    => '0755',
    content => template('dbcostops/startup.sh.erb'),
  }

  file { "${dbcostops::params::config_dir}/scripts/shutdown.sh":
    ensure  => file,
    owner   => $dbcostops::params::user,
    group   => $dbcostops::params::group,
    mode    => '0755',
    content => template('dbcostops/shutdown.sh.erb'),
  }

  file { "${dbcostops::params::config_dir}/scripts/health_check.sh":
    ensure  => file,
    owner   => $dbcostops::params::user,
    group   => $dbcostops::params::group,
    mode    => '0755',
    content => template('dbcostops/health_check.sh.erb'),
  }

}
