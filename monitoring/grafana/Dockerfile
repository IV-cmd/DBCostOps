FROM grafana/grafana:10.1.0

# Copy datasource provisioning config
COPY config/02-datasources.yml /etc/grafana/provisioning/datasources/datasources.yml

# Copy dashboard provider provisioning config
COPY config/03-dashboard-settings.yml /etc/grafana/provisioning/dashboards/dashboards.yml

# Copy dashboard JSON files
COPY dashboards/ /var/lib/grafana/dashboards/

# Set environment variables
ENV GF_SECURITY_ADMIN_USER=admin
ENV GF_SECURITY_ADMIN_PASSWORD=admin
ENV GF_INSTALL_PLUGINS=grafana-clock-panel
ENV GF_ANALYTICS_REPORTING_ENABLED=false
ENV GF_ANALYTICS_CHECK_FOR_UPDATES=false
ENV GF_USERS_ALLOW_SIGN_UP=false

# Expose port
EXPOSE 3000

# Health check — start-period allows time for Grafana to initialize
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
  CMD curl -f http://localhost:3000/api/health || exit 1
