# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

FROM openbao/openbao:latest

# Install curl for health checks and bash for scripts
RUN apk add --no-cache curl bash

# Set working directory
WORKDIR /vault

# Create necessary directories
RUN mkdir -p /vault/config /vault/data

# Copy configuration files
COPY vault-config.hcl /vault/config/
COPY vault-dev-persistent.hcl /vault/config/
COPY init-and-start.sh /vault/

# Make script executable
RUN chmod +x /vault/init-and-start.sh

# Default command will be overridden by docker-compose
CMD ["/vault/init-and-start.sh"]