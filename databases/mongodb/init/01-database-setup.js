const config = {
  databaseName: 'dbcostops_monitoring',
  monitorUser: 'dbcostops_monitor',
  monitorPassword: 'monitor_password'
};

// Connect to admin database
db = db.getSiblingDB('admin');

// Create monitoring user if it doesn't exist
try {
  db.createUser({
    user: config.monitorUser,
    pwd: config.monitorPassword,
    roles: [
      { role: 'readAnyDatabase', db: 'admin' },
      { role: 'clusterMonitor', db: 'admin' },
      { role: 'readWrite', db: config.databaseName }
    ]
  });
  print(`✓ Created monitoring user: ${config.monitorUser}`);
} catch (error) {
  if (error.code === 51003) {
    print(`✓ Monitoring user already exists: ${config.monitorUser}`);
  } else {
    print(`✗ Error creating user: ${error.message}`);
  }
}

// Switch to monitoring database
db = db.getSiblingDB(config.databaseName);

print('MongoDB database setup completed successfully!');
print(`Database: ${config.databaseName}`);
print(`User: ${config.monitorUser}`);
