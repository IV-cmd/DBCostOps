FROM rundeck/rundeck:4.4.0

# Copy configuration files
COPY config/ /home/rundeck/server/config/

# Copy job definitions
COPY jobs/ /home/rundeck/server/projects/dbcostops/jobs/

# Set environment variables
ENV RUNDECK_SERVER_ADDRESS=0.0.0.0
ENV RUNDECK_SERVER_PORT=4440

# Expose port
EXPOSE 4440

# Health check
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=5 \
  CMD curl -f http://localhost:4440/user/login || exit 1
