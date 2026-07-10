class dbcostops::database (
  Optional[String] $type = undef,
  Optional[String] $action = undef,
) {
  if !$type {
    fail("Database type is required")
  }

  if !$action {
    fail("Database action is required")
  }

  if !($action in ['create', 'configure', 'monitor', 'backup', 'restore', 'destroy']) {
    fail("Action must be one of: create, configure, monitor, backup, restore, destroy")
  }

  case $type {
    'postgresql': {
      if $action == 'create' {
        include dbcostops::postgresql
      }
    }
    'mysql': {
      if $action == 'create' {
        include dbcostops::mysql
      }
    }
    'mongodb': {
      if $action == 'create' {
        include dbcostops::mongodb
      }
    }
    default: {
      fail("Unsupported database type: ${type}")
    }
  }
}
