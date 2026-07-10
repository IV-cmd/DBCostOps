class dbcostops::install inherits dbcostops::params {

  group { $dbcostops::params::group:
    ensure => present,
    system => true,
  }

  user { $dbcostops::params::user:
    ensure     => present,
    system     => true,
    shell      => $dbcostops::params::shell,
    home       => $dbcostops::params::home,
    managehome => true,
    groups     => [$dbcostops::params::group],
    require    => Group[$dbcostops::params::group],
  }

  case $facts['os']['family'] {
    'RedHat': {
      # Enable EPEL repository
      package { 'epel-release':
        ensure => present,
        before => Package['dbcostops-core'],
      }
    }
    'Debian': {
      # Update package lists
      exec { 'apt-update':
        command => '/usr/bin/apt-get update',
        refreshonly => true,
        before => Package['dbcostops-core'],
      }
    }
  }

  $core_packages = [
    'python3',
    'python3-pip',
    'git',
    'curl',
    'wget',
    'unzip',
  ]

  package { $core_packages:
    ensure => present,
    before => Package['dbcostops-core'],
  }

  package { 'dbcostops-core':
    ensure   => present,
    provider => $dbcostops::params::package_provider,
    require  => [
      User[$dbcostops::params::user],
      Package[$core_packages],
    ],
  }

  $python_packages = [
    'fastapi',
    'uvicorn',
    'sqlalchemy',
    'pymongo',
        'elasticsearch',
    'prometheus-client',
    'psycopg2-binary',
    'pymysql',
    'pandas',
    'numpy',
    'scikit-learn',
  ]

  package { $python_packages:
    ensure   => present,
    provider => 'pip',
    require  => Package['dbcostops-core'],
  }

  file { "${dbcostops::params::config_dir}/dbcostops.conf":
    ensure  => file,
    owner   => $dbcostops::params::user,
    group   => $dbcostops::params::group,
    mode    => '0644',
    content => template('dbcostops/dbcostops.conf.erb'),
    require => Package['dbcostops-core'],
  }

  file { [$dbcostops::params::log_dir, "${dbcostops::params::log_dir}/archive"]:
    ensure => directory,
    owner  => $dbcostops::params::user,
    group  => $dbcostops::params::group,
    mode   => '0755',
    before => Class['dbcostops::service'],
  }

  file { '/etc/systemd/system/dbcostops.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dbcostops/dbcostops.service.erb'),
    notify  => Class['dbcostops::service'],
    require => Package['dbcostops-core'],
  }

  file { '/etc/systemd/system/dbcostops-api.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dbcostops/dbcostops-api.service.erb'),
    notify  => Class['dbcostops::service'],
    require => Package['dbcostops-core'],
  }

  file { '/etc/logrotate.d/dbcostops':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dbcostops/logrotate.erb'),
    require => Package['dbcostops-core'],
  }

}
