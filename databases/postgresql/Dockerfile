FROM postgres:15

# Copy initialization scripts and config
COPY init/ /docker-entrypoint-initdb.d/
COPY config/postgresql.conf /etc/postgresql/postgresql.conf

# Set environment variables
ENV POSTGRES_DB=dbcostops
ENV POSTGRES_USER=dbcostops_user
ENV POSTGRES_PASSWORD=dbcostops_password

# Expose port
EXPOSE 5432

# Health check — start-period allows time for first-run initialization
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB

# Load custom config file (postgres defaults to $PGDATA/postgresql.conf otherwise)
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
