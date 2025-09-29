# Use Python 3.11 slim image for smaller size
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the main application
COPY register_user.py .

# Create a non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app
USER appuser

# Set environment variables for better Python behavior in containers
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Add healthcheck (optional)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"

# Set the entrypoint to the Python script
ENTRYPOINT ["python", "register_user.py"]

# Add labels for better container metadata
LABEL org.opencontainers.image.title="User Registration Script"
LABEL org.opencontainers.image.description="Python script for registering users in MySQL and publishing to NATS JetStream"
LABEL org.opencontainers.image.vendor="KubeCon SVELTOS NATS Workflows"
LABEL org.opencontainers.image.source="https://github.com/colinjlacy/knapscen-register-users"
