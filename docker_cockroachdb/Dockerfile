# Stage 1: Download and extract CockroachDB
ARG GIT_SHA=865aff1595e494c2ce95030c7a2f20c4370b5ff8
FROM alpine:latest AS downloader

RUN apk add --no-cache curl tar

ARG GIT_SHA
ENV BUILD_URL=https://buildomat.eng.oxide.computer/public/file/oxidecomputer/cockroach/linux-amd64/${GIT_SHA}/cockroach.tgz

WORKDIR /tmp/cockroachdb_download

RUN echo "Downloading CockroachDB from ${BUILD_URL}" && \
    curl -fL -o cockroach.tgz "${BUILD_URL}" && \
    tar -xvzf cockroach.tgz

# Stage 2: Create the final image
FROM alpine:latest

# Install runtime dependencies (ca-certificates for TLS, tzdata for timezones)
RUN apk add --no-cache ca-certificates tzdata libintl gettext # libintl and gettext for libraries CockroachDB might need

WORKDIR /cockroach

# Copy the main binary
COPY --from=downloader /tmp/cockroachdb_download/cockroach/cockroach /usr/local/bin/cockroach

# Copy libraries
# Ensure the target directory exists and then copy. 
# CockroachDB libs might expect to be in a specific relative path or LD_LIBRARY_PATH needs to be set.
RUN mkdir -p /usr/local/lib/cockroach
COPY --from=downloader /tmp/cockroachdb_download/cockroach/lib/* /usr/local/lib/cockroach/

# Copy licenses
COPY --from=downloader /tmp/cockroachdb_download/licenses /licenses

# Set environment variables for the libraries
ENV LD_LIBRARY_PATH=/usr/local/lib/cockroach:${LD_LIBRARY_PATH}

EXPOSE 26257 8080

# Default entrypoint and command
# The official CockroachDB image has a more sophisticated entrypoint script (docker-entrypoint.sh)
# This is a simplified version. For CI, starting a single node is often sufficient.
ENTRYPOINT ["cockroach"]
CMD ["start-single-node", "--insecure", "--store=/cockroach-data/", "--http-addr=0.0.0.0:8080", "--advertise-addr=localhost"] 

# Create a directory for data that can be mounted as a volume
RUN mkdir /cockroach-data
VOLUME /cockroach-data

LABEL maintainer="your-email@example.com"
LABEL description="Custom CockroachDB image built from Oxide Computer tarball."
