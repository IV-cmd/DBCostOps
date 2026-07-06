FROM mysql:8.0

# Copy initialization scripts and config
COPY init/ /docker-entrypoint-initdb.d/
COPY config/my.cnf /etc/mysql/conf.d/my.cnf

# Set environment variables (MYSQL_ROOT_PASSWORD must be provided at runtime)
ENV MYSQL_DATABASE=dbcostops
ENV MYSQL_USER=dbcostops_user
ENV MYSQL_PASSWORD=dbcostops_password

# Expose port
EXPOSE 3306

# Health check — start-period allows time for first-run initialization
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD} || exit 1
