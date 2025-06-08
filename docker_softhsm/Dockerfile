# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

FROM alpine:latest

# Install SoftHSM and OpenSC
RUN apk add --no-cache softhsm opensc

# Create directories
RUN mkdir -p /var/lib/softhsm/tokens

# Copy setup script
COPY setup-softhsm.sh /usr/local/bin/setup-softhsm.sh
RUN chmod +x /usr/local/bin/setup-softhsm.sh

# Set entrypoint to run the setup script
ENTRYPOINT ["/usr/local/bin/setup-softhsm.sh"]
