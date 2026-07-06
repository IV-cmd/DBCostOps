FROM python:3.11-slim

WORKDIR /app

# Copy and install only the API-level dependencies (build context is DBCostOps/ root)
COPY cost_engine/requirements-api.txt .
RUN pip install --no-cache-dir -r requirements-api.txt

# Copy full cost_engine package preserving directory structure
COPY cost_engine/ ./cost_engine/

# Create non-root user
RUN useradd --create-home --shell /bin/bash dbcostops
RUN chown -R dbcostops:dbcostops /app
USER dbcostops

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Set working directory to pricing-api so local imports resolve correctly
WORKDIR /app/cost_engine/pricing-api

# Run the application (cost_api.py — underscore, valid Python module name)
CMD ["uvicorn", "cost_api:app", "--host", "0.0.0.0", "--port", "8000"]
