# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

FROM almalinux:latest

# Install required packages including SoftHSM, and dependencies
RUN dnf install -y epel-release && \
    dnf install -y \
        wget \
        bash \
        ca-certificates \
        softhsm \
        opensc \
        pkcs11-helper \
        glibc-devel && \
    dnf clean all

# Download and install OpenBao HSM-enabled RPM
RUN wget https://github.com/openbao/openbao/releases/download/v2.2.2/bao-hsm_2.2.2_linux_amd64.rpm -O /tmp/bao-hsm.rpm && \
    dnf install -y /tmp/bao-hsm.rpm && \
    rm /tmp/bao-hsm.rpm

# Create vault user and group
RUN groupadd --gid 1000 vault && \
    useradd --uid 1000 --gid vault --shell /bin/bash --create-home vault

# Set working directory
WORKDIR /vault

# Create necessary directories
RUN mkdir -p /vault/config /vault/data /vault/logs && \
    chown -R vault:vault /vault

# Set SoftHSM configuration path
ENV SOFTHSM2_CONF=/etc/softhsm2.conf

# Copy configuration files
COPY vault-config.hcl /vault/config/
COPY vault-dev-persistent.hcl /vault/config/
COPY --chmod=755 init-and-start.sh /vault/

# Set ownership
RUN chown -R vault:vault /vault

# Expose OpenBao port
EXPOSE 8200

# Don't switch to vault user yet - let the init script handle permissions first
# USER vault

# Default command will be overridden by docker-compose
CMD ["/vault/init-and-start.sh"]