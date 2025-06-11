#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# CockroachDB health check script
# Validates database connectivity and certificate status
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[HEALTH]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[HEALTH]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[HEALTH]${NC} $1"
}

log_error() {
    echo -e "${RED}[HEALTH]${NC} $1"
}

# Configuration
CERT_DIR="${CERT_DIR:-/cockroach/certs}"
COCKROACH_HOST="${COCKROACH_HOST:-localhost}"
COCKROACH_PORT="${COCKROACH_PORT:-26257}"
HTTP_PORT="${HTTP_PORT:-8080}"

# Function to check certificate expiry
check_certificate_health() {
    local cert_file="$1"
    local cert_name="$2"
    
    if [ ! -f "$cert_file" ]; then
        log_error "$cert_name certificate not found: $cert_file"
        return 1
    fi
    
    # Check if certificate is valid
    if ! openssl x509 -in "$cert_file" -noout -checkend 0; then
        log_error "$cert_name certificate has expired"
        return 1
    fi
    
    # Check expiry time
    local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry_date" +%s)
    local current_epoch=$(date +%s)
    local hours_remaining=$(( (expiry_epoch - current_epoch) / 3600 ))
    
    if [ $hours_remaining -lt 24 ]; then
        log_warning "$cert_name certificate expires in $hours_remaining hours"
    else
        log_success "$cert_name certificate valid for $hours_remaining hours"
    fi
    
    return 0
}

# Function to check CockroachDB connectivity
check_database_connectivity() {
    log_info "Checking CockroachDB connectivity..."
    
    # Check if CockroachDB process is running
    if ! pgrep -f cockroach > /dev/null; then
        log_error "CockroachDB process not running"
        return 1
    fi
    
    # Check TCP connectivity
    if ! nc -z $COCKROACH_HOST $COCKROACH_PORT; then
        log_error "Cannot connect to CockroachDB on $COCKROACH_HOST:$COCKROACH_PORT"
        return 1
    fi
    
    # Check HTTP admin interface
    if ! nc -z $COCKROACH_HOST $HTTP_PORT; then
        log_warning "Cannot connect to CockroachDB admin interface on $COCKROACH_HOST:$HTTP_PORT"
    else
        log_success "CockroachDB admin interface accessible"
    fi
    
    # Try to execute a simple SQL query using the admin interface
    local health_response=$(curl -s -k --max-time 5 "http://$COCKROACH_HOST:$HTTP_PORT/health" 2>/dev/null || echo "")
    
    if [ -n "$health_response" ]; then
        log_success "CockroachDB health endpoint responding"
    else
        log_warning "CockroachDB health endpoint not responding"
    fi
    
    log_success "CockroachDB connectivity check passed"
    return 0
}

# Function to check certificate renewal daemon
check_renewal_daemon() {
    log_info "Checking certificate renewal daemon..."
    
    if pgrep -f "renew-certificates.sh daemon" > /dev/null; then
        log_success "Certificate renewal daemon is running"
        return 0
    else
        log_warning "Certificate renewal daemon not found"
        return 1
    fi
}

# Main health check function
run_health_check() {
    local exit_code=0
    
    log_info "🏥 Starting CockroachDB health check..."
    
    # Check certificates
    log_info "📋 Checking certificate health..."
    check_certificate_health "$CERT_DIR/ca.crt" "CA" || exit_code=1
    check_certificate_health "$CERT_DIR/node.crt" "Server" || exit_code=1
    check_certificate_health "$CERT_DIR/client.root.crt" "Client" || exit_code=1
    
    # Check database connectivity
    check_database_connectivity || exit_code=1
    
    # Check renewal daemon
    check_renewal_daemon || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        log_success "🎉 All health checks passed!"
    else
        log_error "❌ Some health checks failed"
    fi
    
    return $exit_code
}

# Handle script arguments
case "${1:-check}" in
    "check"|"")
        run_health_check
        ;;
    "certificates")
        log_info "Checking certificate health only..."
        check_certificate_health "$CERT_DIR/ca.crt" "CA"
        check_certificate_health "$CERT_DIR/node.crt" "Server"
        check_certificate_health "$CERT_DIR/client.root.crt" "Client"
        ;;
    "connectivity")
        log_info "Checking database connectivity only..."
        check_database_connectivity
        ;;
    "daemon")
        log_info "Checking renewal daemon only..."
        check_renewal_daemon
        ;;
    *)
        echo "Usage: $0 [check|certificates|connectivity|daemon]"
        echo "  check         - Run all health checks (default)"
        echo "  certificates  - Check certificate health only"
        echo "  connectivity  - Check database connectivity only"
        echo "  daemon        - Check renewal daemon only"
        exit 1
        ;;
esac
