FROM alpine:latest

# Install SoftHSM and OpenSC (for pkcs11-tool, useful for key management)
RUN apk add --no-cache softhsm opensc

# Create the directory for SoftHSM tokens
RUN mkdir -p /var/lib/softhsm/tokens

# Copy the setup script into the image
COPY setup-softhsm.sh /usr/local/bin/setup-softhsm.sh
RUN chmod +x /usr/local/bin/setup-softhsm.sh

# The script will be run by docker-compose command or entrypoint
CMD ["/usr/local/bin/setup-softhsm.sh"]
