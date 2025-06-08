# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

FROM openbao/openbao:latest

# Install curl for health checks
RUN apk add --no-cache curl

# Set working directory
WORKDIR /vault

# Copy any additional configuration files here if needed
# COPY vault-config.hcl /vault/config/

# Default command will be overridden by docker-compose
CMD ["bao", "server", "-dev"]