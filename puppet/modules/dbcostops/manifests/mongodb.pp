class dbcostops::mongodb (
  String $version = lookup('databases.mongodb.version', { 'default_value' => '7.0' }),
  String $storage_engine = lookup('databases.mongodb.storage_engine', { 'default_value' => 'wiredTiger' }),
  String $data_dir = lookup('databases.mongodb.data_dir', { 'default_value' => '/var/lib/mongodb' }),
) {
  if !($version =~ /^\d+\.\d+$/) {
    fail("MongoDB version must be in format X.Y")
  }

  package { "mongodb-org-${version}":
    ensure => present,
  }

  service { 'mongod':
    ensure => running,
    enable => true,
    require => Package["mongodb-org-${version}"],
  }
}
