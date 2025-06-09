# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

FROM almalinux:latest

# Install SoftHSM and OpenSC
RUN dnf install -y epel-release && \
    dnf install -y softhsm opensc && \
    dnf clean all

# Create directories
RUN mkdir -p /var/lib/softhsm/tokens /etc/softhsm2.d

# Set SoftHSM configuration path
ENV SOFTHSM2_CONF=/etc/softhsm2.conf

# Copy setup script and make executable
COPY setup-softhsm.sh /usr/local/bin/setup-softhsm.sh
RUN chmod +x /usr/local/bin/setup-softhsm.sh && \
    ls -la /usr/local/bin/setup-softhsm.sh

# Set entrypoint to run the setup script
ENTRYPOINT ["/bin/sh", "/usr/local/bin/setup-softhsm.sh"]
