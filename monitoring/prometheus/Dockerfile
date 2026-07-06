FROM prom/prometheus:v2.45.0

# Copy configuration files (includes prometheus.yml and alerting rules)
COPY config/ /etc/prometheus/

# Expose port
EXPOSE 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9090/-/healthy || exit 1
