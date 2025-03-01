FROM python:3.11-slim

# Set a non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Set the working directory
WORKDIR /docs

# Copy all project files into the image
COPY . /docs

# Install MkDocs, Material theme, and curl
RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir mkdocs-material

# Expose the MkDocs default port
EXPOSE 8000

# Add a health check using Python
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD python3 -c "import http.client; conn = http.client.HTTPConnection('localhost', 8000); conn.request('HEAD', '/'); resp = conn.getresponse(); exit(0) if resp.status == 200 else exit(1)"

# Switch to non-root user
USER appuser

# Start MkDocs server
CMD ["mkdocs", "serve", "--dev-addr=0.0.0.0:8000"]
