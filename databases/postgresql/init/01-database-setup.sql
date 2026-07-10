-- Database and user configuration
\set db_name dbcostops_monitoring
\set monitor_user dbcostops_monitor
\set monitor_password monitor_password

-- Create monitoring user with secure password
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = :'monitor_user') THEN
        CREATE ROLE :monitor_user WITH LOGIN PASSWORD :'monitor_password';
        RAISE NOTICE 'Created monitoring user: %', :'monitor_user';
    ELSE
        RAISE NOTICE 'Monitoring user already exists: %', :'monitor_user';
    END IF;
END $$;

-- Create monitoring database if it doesn't exist
SELECT 'CREATE DATABASE ' || :'db_name'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'db_name')\gexec

-- Grant privileges to monitoring user
GRANT ALL PRIVILEGES ON DATABASE :db_name TO :monitor_user;

-- Connect to monitoring database
\c :db_name

-- Enable required extensions for monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

\echo 'PostgreSQL database setup completed successfully!'
\echo 'Database: :' || :'db_name'
\echo 'User: :' || :'monitor_user'
