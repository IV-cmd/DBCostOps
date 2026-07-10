class dbcostops::postgresql (
  String $version = lookup('databases.postgresql.version', { 'default_value' => '15' }),
  Integer $max_connections = lookup('databases.postgresql.max_connections', { 'default_value' => 100 }),
  String $data_dir = lookup('databases.postgresql.data_dir', { 'default_value' => '/var/lib/postgresql/data' }),
) {
  if !($version =~ /^\d+(\.\d+)?$/) {
    fail("PostgreSQL version must be in format X or X.Y")
  }

  package { "postgresql-${version}":
    ensure => present,
  }

  service { 'postgresql':
    ensure => running,
    enable => true,
    require => Package["postgresql-${version}"],
  }
}
