FROM docker.elastic.co/kibana/kibana:8.11.0

# Copy configuration files
COPY config/ /usr/share/kibana/config/

# Set environment variables
ENV ELASTICSEARCH_HOSTS=http://elasticsearch:9200

# Expose port
EXPOSE 5601

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
  CMD curl -f http://localhost:5601/api/status || exit 1
