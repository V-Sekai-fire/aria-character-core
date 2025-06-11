#!/bin/bash
# Simple command tracer with timestamps for macOS
# Usage: ./trace-cmd.sh [timeout_seconds] command [args...]

# Function to log with timestamp
trace_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] TRACE: $1"
}

# Check if timeout is provided
if [[ $1 =~ ^[0-9]+$ ]]; then
    TIMEOUT_SECONDS=$1
    shift
    CMD="$@"
    
    trace_log "Starting command with ${TIMEOUT_SECONDS}s timeout: $CMD"
    START_TIME=$(date +%s.%N)
    
    # Run with timeout
    if timeout $TIMEOUT_SECONDS "$@"; then
        END_TIME=$(date +%s.%N)
        DURATION=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "N/A")
        trace_log "Command completed successfully in ${DURATION}s"
        exit 0
    else
        EXIT_CODE=$?
        END_TIME=$(date +%s.%N)
        DURATION=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "N/A")
        
        if [ $EXIT_CODE -eq 124 ]; then
            trace_log "Command timed out after ${TIMEOUT_SECONDS}s (duration: ${DURATION}s)"
        else
            trace_log "Command failed with exit code $EXIT_CODE (duration: ${DURATION}s)"
        fi
        exit $EXIT_CODE
    fi
else
    # No timeout, just trace
    CMD="$@"
    trace_log "Starting command: $CMD"
    START_TIME=$(date +%s.%N)
    
    if "$@"; then
        END_TIME=$(date +%s.%N)
        DURATION=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "N/A")
        trace_log "Command completed successfully in ${DURATION}s"
        exit 0
    else
        EXIT_CODE=$?
        END_TIME=$(date +%s.%N)
        DURATION=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "N/A")
        trace_log "Command failed with exit code $EXIT_CODE (duration: ${DURATION}s)"
        exit $EXIT_CODE
    fi
fi
