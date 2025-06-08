download-cockroach-tar:
    @echo "Downloading CockroachDB tarball..."
    @curl -L -o cockroachdb.tar https://github.com/V-Sekai/cockroach/releases/download/cockroach-2/cockroachdb.tar
    @echo "Download complete: cockroachdb.tar"

load-cockroach-docker: download-cockroach-tar
    @echo "Loading cockroachdb.tar into Docker..."
    @docker load -i cockroachdb.tar
    @echo "Docker image loaded."

up: load-cockroach-docker
    @echo "Starting all services..."
    @docker-compose up -d

down:
    @docker-compose down
