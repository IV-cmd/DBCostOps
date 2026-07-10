-- Create monitoring user if it doesn't exist
CREATE USER IF NOT EXISTS 'dbcostops_monitor'@'%' IDENTIFIED BY 'monitor_password';

-- Create monitoring database if it doesn't exist
CREATE DATABASE IF NOT EXISTS dbcostops_monitoring
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Grant privileges to monitoring user
GRANT ALL PRIVILEGES ON dbcostops_monitoring.* TO 'dbcostops_monitor'@'%';

-- Flush privileges to ensure changes take effect
FLUSH PRIVILEGES;

SELECT 'MySQL database setup completed successfully!' as status;
SELECT 'Database: dbcostops_monitoring' as database_info;
SELECT 'User: dbcostops_monitor' as user_info;
