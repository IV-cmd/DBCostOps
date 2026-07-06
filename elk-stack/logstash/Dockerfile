FROM docker.elastic.co/logstash/logstash:8.11.0

# Copy pipeline config files only (no subdirectories)
COPY config/*.conf /usr/share/logstash/pipeline/

# Copy index templates to a dedicated directory
COPY config/templates/ /usr/share/logstash/templates/

# Set environment variables
ENV LS_JAVA_OPTS="-Xmx1g -Xms1g"

# Expose Beats port, Logstash monitoring API, and all TCP input ports
EXPOSE 5044 9600 5000 5001 5002 5003 5004 5005 5006

# Health check — start-period allows time for Logstash to connect to Elasticsearch
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD curl -f http://localhost:9600/_node/stats || exit 1
