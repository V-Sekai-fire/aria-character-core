# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

FROM openbao/openbao-hsm-ubi

# Check if curl and bash are available and set working directory

# Set working directory
WORKDIR /vault

# Create necessary directories
RUN mkdir -p /vault/config /vault/data

# Copy configuration files
COPY vault-config.hcl /vault/config/
COPY vault-dev-persistent.hcl /vault/config/
COPY --chmod=755 init-and-start.sh /vault/

# Default command will be overridden by docker-compose
CMD ["/vault/init-and-start.sh"]