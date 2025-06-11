#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Windows-style machine ID generator
# Generates identifiers like DESKTOP-ABC123, LAPTOP-XYZ789, etc.

# Function to generate a random alphanumeric string
generate_random_suffix() {
    openssl rand -hex 3 | tr '[:lower:]' '[:upper:]'
}

# Function to generate machine ID based on service type
generate_machine_id() {
    local service_type="${1:-UNKNOWN}"
    local prefix=""
    
    case "$service_type" in
        "cockroachdb"|"database"|"db")
            prefix="DBSRV"
            ;;
        "openbao"|"vault"|"security")
            prefix="VTSRV"
            ;;
        "auth"|"authentication")
            prefix="AUTHSV"
            ;;
        "storage"|"store")
            prefix="STORSV"
            ;;
        "queue"|"messaging")
            prefix="QUEUESV"
            ;;
        "engine"|"compute")
            prefix="ENGINESV"
            ;;
        "interface"|"ui"|"web")
            prefix="WEBSRV"
            ;;
        "monitor"|"monitoring")
            prefix="MONSRV"
            ;;
        "coordinate"|"coord")
            prefix="COORDSV"
            ;;
        *)
            prefix="ARIASRV"
            ;;
    esac
    
    # Generate 6-character random suffix
    local suffix=$(generate_random_suffix)
    
    echo "${prefix}-${suffix}"
}

# Main execution
SERVICE_TYPE="${1:-openbao}"
generate_machine_id "$SERVICE_TYPE"
