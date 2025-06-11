# Performance Tracing Standard Operating Procedure

## Overview

This document outlines the standard operating procedures for performance monitoring, tracing, and debugging of the Aria Character Core OpenBao HSM deployment on Fly.io.

**Decision Context:** This SOP implements lightweight command tracing with timeouts to address reliability issues where Fly.io commands were hanging indefinitely without timeout protection, making debugging difficult and operations unreliable.

**Selected Solution:** Custom lightweight tracer over alternatives like DTrace (too complex) or external APM tools (unnecessary cost/complexity).

## Tools and Scripts

### 1. Command Tracer (`scripts/trace-cmd.sh`)

A lightweight command execution tracer with timestamp logging for macOS environments.

**Usage:**
```bash
# With timeout
./scripts/trace-cmd.sh 30 fly status --app aria-character-core-bao

# Without timeout
./scripts/trace-cmd.sh fly logs --app aria-character-core-bao
```

**Features:**
- Timestamps with millisecond precision
- Timeout support with duration tracking
- Exit code tracking
- Simple execution time measurement

### 2. Available macOS Performance Tools

#### Built-in Tools
- `time` - Basic command timing
- `sample` - Process sampling and profiling
- `spindump` - System-wide activity sampling
- `dtrace` - Dynamic tracing (requires admin privileges)
- `top` - Real-time process monitoring

#### Usage Examples
```bash
# Basic timing
/usr/bin/time -p fly status --app aria-character-core-bao

# Process sampling (requires PID)
sample [PID] 10 -file output.txt

# System activity dump
spindump -reveal -timelimit 10 -o system_trace.txt
```

## Standard Procedures

### 1. Fly.io Command Tracing

For all Fly.io operations, use timeouts to prevent hanging commands:

```bash
# Status checks (30 second timeout)
./scripts/trace-cmd.sh 30 fly status --app aria-character-core-bao

# Log retrieval (60 second timeout)
./scripts/trace-cmd.sh 60 fly logs --app aria-character-core-bao

# Deployment monitoring (300 second timeout)
./scripts/trace-cmd.sh 300 fly deploy --app aria-character-core-bao --config fly-bao.toml
```

### 2. OpenBao Service Monitoring

#### Health Check Procedure
1. **Service Status**
   ```bash
   ./scripts/trace-cmd.sh 15 fly status --app aria-character-core-bao
   ```

2. **Log Analysis**
   ```bash
   ./scripts/trace-cmd.sh 30 fly logs --app aria-character-core-bao --lines 50
   ```

3. **API Connectivity**
   ```bash
   ./scripts/trace-cmd.sh 10 curl -s -o /dev/null -w "%{http_code}" http://aria-character-core-bao.fly.dev:8200/v1/sys/health
   ```

#### Performance Baseline Establishment
```bash
# Record baseline metrics
date > performance_baseline.log
./scripts/trace-cmd.sh 30 fly status --app aria-character-core-bao >> performance_baseline.log
./scripts/trace-cmd.sh 30 fly logs --app aria-character-core-bao --lines 20 >> performance_baseline.log
```

### 3. Certificate Generation Testing

When testing OpenBao for certificate generation (e.g., for CockroachDB):

```bash
# 1. Verify OpenBao is running
./scripts/trace-cmd.sh 15 fly status --app aria-character-core-bao

# 2. Test API connectivity
./scripts/trace-cmd.sh 10 curl -s http://aria-character-core-bao.fly.dev:8200/v1/sys/health

# 3. Initialize if needed (first time only)
./scripts/trace-cmd.sh 60 curl -s -X POST http://aria-character-core-bao.fly.dev:8200/v1/sys/init

# 4. Enable PKI engine for certificate generation
./scripts/trace-cmd.sh 30 curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  http://aria-character-core-bao.fly.dev:8200/v1/sys/mounts/pki \
  -d '{"type":"pki","config":{"max_lease_ttl":"87600h"}}'
```

## Troubleshooting Procedures

### 1. Command Timeout Issues

**Symptoms:** Commands hang or timeout frequently
**Actions:**
1. Check network connectivity
2. Verify Fly.io service status
3. Increase timeout values for complex operations
4. Use trace logging to identify bottlenecks

### 2. OpenBao Service Crashes

**Symptoms:** Service restarts, segmentation faults in logs
**Actions:**
1. Check logs for HSM-related errors
2. Verify fallback configuration is working
3. Monitor resource usage
4. Review container compatibility issues

### 3. Performance Degradation

**Symptoms:** Slower response times, higher resource usage
**Actions:**
1. Compare against baseline metrics
2. Use system-wide tracing tools
3. Analyze log patterns
4. Check Fly.io region performance

## Monitoring Thresholds

| Metric | Normal | Warning | Critical |
|--------|--------|---------|----------|
| Command Response Time | < 5s | 5-15s | > 15s |
| Service Restart Count | 0/hour | 1-2/hour | > 3/hour |
| Memory Usage | < 80% | 80-90% | > 90% |
| HTTP Response Time | < 2s | 2-5s | > 5s |

## Emergency Procedures

### 1. Service Recovery
```bash
# Quick restart
./scripts/trace-cmd.sh 60 fly restart --app aria-character-core-bao

# Force rebuild and deploy
./scripts/trace-cmd.sh 300 fly deploy --app aria-character-core-bao --config fly-bao.toml --dockerfile Dockerfile.openbao
```

### 2. Data Backup
```bash
# Backup volume data (if accessible)
./scripts/trace-cmd.sh 120 fly ssh console --app aria-character-core-bao --command "tar -czf /vault/backup-$(date +%Y%m%d-%H%M%S).tar.gz /vault/data"
```

## Security Considerations

1. **Trace Logs:** May contain sensitive information - handle securely
2. **API Tokens:** Never log vault tokens or sensitive credentials
3. **Performance Data:** May reveal system architecture - restrict access
4. **Debug Information:** Sanitize before sharing with external parties

## Automation Scripts

### Daily Health Check
```bash
#!/bin/bash
# daily-health-check.sh
DATE=$(date +%Y%m%d)
LOG_FILE="health-check-$DATE.log"

echo "=== Daily Health Check: $DATE ===" > $LOG_FILE
./scripts/trace-cmd.sh 30 fly status --app aria-character-core-bao >> $LOG_FILE
./scripts/trace-cmd.sh 30 fly logs --app aria-character-core-bao --lines 10 >> $LOG_FILE
./scripts/trace-cmd.sh 10 curl -s -w "HTTP Status: %{http_code}, Time: %{time_total}s\n" \
  http://aria-character-core-bao.fly.dev:8200/v1/sys/health >> $LOG_FILE
```

### Performance Benchmark
```bash
#!/bin/bash
# performance-benchmark.sh
echo "=== Performance Benchmark ===" 
for i in {1..5}; do
  echo "Test $i:"
  ./scripts/trace-cmd.sh 30 curl -s -w "Time: %{time_total}s\n" \
    http://aria-character-core-bao.fly.dev:8200/v1/sys/health
  sleep 2
done
```

## Success Criteria & Review Schedule

### Success Metrics (from Implementation Decision)
- **Reliability:** No more hanging commands during operations
- **Visibility:** Clear timing data for all critical operations  
- **Usability:** Simple interface that team members can adopt quickly
- **Maintainability:** Minimal code that's easy to understand and modify

### Performance Review Schedule
- **30 days:** Initial effectiveness review
- **90 days:** Full feature assessment
- **Quarterly:** Ongoing optimization reviews

### Dependencies
- **System Requirements:** macOS with standard Unix tools, Bash shell, `timeout` command
- **External Services:** Fly.io CLI tool, Curl for HTTP testing, OpenBao API availability

## Alternative Tools Considered

### DTrace (Not Used)
- **Pros:** Comprehensive system tracing, built-in to macOS, low overhead
- **Cons:** Requires admin privileges, complex syntax, not available in containers
- **Usage:** `sudo dtrace -n 'syscall:::entry { trace(execname); }'`

### External APM Tools (Not Used)  
- **Pros:** Professional features, cloud dashboards, advanced analytics
- **Cons:** Additional cost/complexity, external dependencies, data privacy concerns

### Built-in Shell Tools Only (Insufficient)
- **Pros:** Universal availability, no additional code
- **Cons:** Inconsistent timeout behavior, no standardized logging

## Risk Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Script failures | Medium | Low | Comprehensive testing, fallback procedures |
| Timeout too short | Low | Medium | Configurable values, monitoring adjustment |
| Performance overhead | Low | Low | Lightweight implementation |
| Team adoption | Medium | Low | Training and documentation |

## Contact Information

- **Primary Engineer:** Aria AI Assistant (GitHub Copilot)
- **Backup Engineer:** Aria Character Core Development Team
- **Escalation:** Aria Project Lead / System Administrator
- **External Support:** Fly.io Support, OpenBao Community

## Document Version

- **Version:** 1.0
- **Last Updated:** June 11, 2025
- **Next Review:** July 11, 2025
- **Approved By:** Aria AI Assistant - Technical Lead

---

*This document should be reviewed and updated quarterly or after any major system changes.*
