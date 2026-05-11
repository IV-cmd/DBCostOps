-- Database and user configuration
SET @db_name = 'dbcostops_monitoring';
SET @monitor_user = 'dbcostops_monitor';
SET @monitor_password = 'monitor_password';

-- Create monitoring user if it doesn't exist
CREATE USER IF NOT EXISTS @monitor_user@'%' IDENTIFIED BY @monitor_password;

-- Create monitoring database if it doesn't exist
CREATE DATABASE IF NOT EXISTS @db_name 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Grant privileges to monitoring user
GRANT ALL PRIVILEGES ON @db_name.* TO @monitor_user@'%';

-- Flush privileges to ensure changes take effect
FLUSH PRIVILEGES;

SELECT 'MySQL database setup completed successfully!' as status;
SELECT CONCAT('Database: ', @db_name) as database_info;
SELECT CONCAT('User: ', @monitor_user) as user_info;
