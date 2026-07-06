FROM mongo:7.0

# Copy initialization scripts and config
COPY init/ /docker-entrypoint-initdb.d/
COPY config/mongod.conf /etc/mongod.conf

# Set environment variables
ENV MONGO_INITDB_DATABASE=dbcostops_monitoring

# Expose port
EXPOSE 27017

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD mongosh --eval "db.adminCommand('ping')" --quiet
