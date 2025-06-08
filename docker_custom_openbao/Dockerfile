# Start from an official OpenBao image
ARG OPENBAO_VERSION=latest
FROM openbao/openbao:${OPENBAO_VERSION}

# Install curl for health checks
RUN apk add --no-cache curl

# Example: Add custom scripts, plugins, or configurations if needed
# COPY my-custom-plugin /usr/local/bin/my-custom-plugin
# COPY my-openbao-config-template.hcl /openbao/config/config-template.hcl

# Ensure any necessary tools or libraries for PKCS#11 are present
# The base openbao image might already include what's needed for libsofthsm2.so to be used by the pkcs11 seal.
# If not, you might need to install them. For example, on an Alpine-based image:
# RUN apk add --no-cache softhsm

# The default entrypoint and command from the base image should suffice unless you need to override them.

LABEL maintainer="your-email@example.com"
LABEL description="Custom OpenBao image with specific configurations/tools."
