#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Certificate renewal script for Aria services
# Handles automatic certificate renewal before expiry

set -e

# Configuration
CERT_DIR="${CERT_DIR:-/cockroach/certs}"
SERVICE_TYPE="${SERVICE_TYPE:-cockroachdb-server}"
RENEWAL_THRESHOLD="${RENEWAL_THRESHOLD:-24}" # Renew when less than 24 hours remain
CHECK_INTERVAL="${CHECK_INTERVAL:-3600}" # Check every hour

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

# Function to check certificate expiry
check_certificate_expiry() {
    local cert_file="$1"
    
    if [ ! -f "$cert_file" ]; then
        log_warning "Certificate file not found: $cert_file"
        return 1
    fi
    
    # Get certificate expiry time
    local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry_date" +%s)
    local current_epoch=$(date +%s)
    local hours_remaining=$(( (expiry_epoch - current_epoch) / 3600 ))
    
    log_info "Certificate expires in $hours_remaining hours"
    
    if [ $hours_remaining -lt $RENEWAL_THRESHOLD ]; then
        log_warning "Certificate expires in less than $RENEWAL_THRESHOLD hours, renewal needed"
        return 0 # Needs renewal
    else
        log_info "Certificate is valid for $hours_remaining hours, no renewal needed"
        return 1 # No renewal needed
    fi
}

# Function to renew certificates
renew_certificates() {
    log_info "Starting certificate renewal process..."
    
    # Backup existing certificates
    local backup_dir="$CERT_DIR/backup-$(date +%s)"
    mkdir -p "$backup_dir"
    
    if [ -f "$CERT_DIR/node.crt" ]; then
        cp "$CERT_DIR"/*.{crt,key} "$backup_dir/" 2>/dev/null || true
        log_info "Backed up existing certificates to $backup_dir"
    fi
    
    # Fetch new certificates
    if /usr/local/bin/fetch-certificates.sh; then
        log_success "Certificate renewal completed successfully"
        
        # Signal CockroachDB to reload certificates if running
        if pgrep -f cockroach > /dev/null; then
            log_info "Signaling CockroachDB to reload certificates..."
            # CockroachDB automatically reloads certificates when files change
            # No explicit signal needed, but we can log the action
            log_info "CockroachDB will automatically detect new certificates"
        fi
        
        # Clean up old backup if renewal was successful
        rm -rf "$backup_dir"
        
        return 0
    else
        log_error "Certificate renewal failed, restoring backup"
        
        # Restore backup
        if [ -d "$backup_dir" ] && [ "$(ls -A $backup_dir 2>/dev/null)" ]; then
            cp "$backup_dir"/*.{crt,key} "$CERT_DIR/" 2>/dev/null || true
            log_info "Restored certificates from backup"
        fi
        
        return 1
    fi
}

# Main renewal loop
run_renewal_daemon() {
    log_info "Starting certificate renewal daemon"
    log_info "Renewal threshold: $RENEWAL_THRESHOLD hours"
    log_info "Check interval: $CHECK_INTERVAL seconds"
    
    while true; do
        # Determine which certificate to check based on service type
        case "$SERVICE_TYPE" in
            "cockroachdb-server")
                cert_file="$CERT_DIR/node.crt"
                ;;
            "cockroachdb-client")
                cert_file="$CERT_DIR/client.root.crt"
                ;;
            *)
                cert_file="$CERT_DIR/${SERVICE_TYPE}.crt"
                ;;
        esac
        
        if check_certificate_expiry "$cert_file"; then
            if renew_certificates; then
                log_success "Certificate renewal completed successfully"
            else
                log_error "Certificate renewal failed, will retry on next check"
            fi
        fi
        
        log_info "Next certificate check in $CHECK_INTERVAL seconds"
        sleep $CHECK_INTERVAL
    done
}

# Handle script arguments
case "${1:-daemon}" in
    "daemon")
        run_renewal_daemon
        ;;
    "check")
        case "$SERVICE_TYPE" in
            "cockroachdb-server")
                cert_file="$CERT_DIR/node.crt"
                ;;
            "cockroachdb-client")
                cert_file="$CERT_DIR/client.root.crt"
                ;;
            *)
                cert_file="$CERT_DIR/${SERVICE_TYPE}.crt"
                ;;
        esac
        
        if check_certificate_expiry "$cert_file"; then
            echo "RENEWAL_NEEDED"
            exit 0
        else
            echo "RENEWAL_NOT_NEEDED"
            exit 1
        fi
        ;;
    "renew")
        if renew_certificates; then
            log_success "Manual certificate renewal completed"
            exit 0
        else
            log_error "Manual certificate renewal failed"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 [daemon|check|renew]"
        echo "  daemon - Run continuous renewal daemon (default)"
        echo "  check  - Check if renewal is needed and exit"
        echo "  renew  - Force certificate renewal and exit"
        exit 1
        ;;
esac
