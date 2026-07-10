class dbcostops::mysql (
  String $version = lookup('databases.mysql.version', { 'default_value' => '8.0' }),
  Integer $max_connections = lookup('databases.mysql.max_connections', { 'default_value' => 150 }),
  String $data_dir = lookup('databases.mysql.data_dir', { 'default_value' => '/var/lib/mysql' }),
) {
  if !($version =~ /^\d+\.\d+$/) {
    fail("MySQL version must be in format X.Y")
  }

  package { "mysql-community-server-${version}":
    ensure => present,
  }

  service { 'mysql':
    ensure => running,
    enable => true,
    require => Package["mysql-community-server-${version}"],
  }
}
