# R25W1900007 - TimescaleDB Integration

## Status

Proposed

## Context

The Neon Frontlines City Block simulator requires efficient time-series storage for operative activities, transfer events, and performance metrics, with hypertable optimization for high-volume simulation data.

## Decision

Integrate TimescaleDB for time-series event storage with the following capabilities:

1. **Hypertable Optimization**: Automatic partitioning for time-series performance
2. **Operative Activity Logging**: Complete audit trail of all operative actions
3. **Transfer Event Storage**: Block transfer history with performance metrics
4. **Analytics Queries**: Efficient aggregation and analysis of simulation data

## Implementation Plan

### Phase 1: Database Schema Design

- [ ] Create TimescaleDB hypertables for operative activities
- [ ] Design transfer event storage schema
- [ ] Implement performance metrics tables
- [ ] Add proper indexing for time-series queries

### Phase 2: Event Logging Integration

- [ ] Create `AriaNeonFrontlines.Storage.EventLogger` module
- [ ] Implement operative action logging with timestamps
- [ ] Add transfer event recording with metadata
- [ ] Build performance metrics collection and storage

### Phase 3: Query Optimization

- [ ] Implement efficient time-range queries for analytics
- [ ] Add aggregation functions for performance analysis
- [ ] Create operative behavior pattern queries
- [ ] Build transfer performance analytics

### Phase 4: Data Retention Policies

- [ ] Implement data retention policies for simulation runs
- [ ] Add data compression for historical simulation data
- [ ] Create data export capabilities for analysis
- [ ] Build cleanup procedures for old simulation data

## Database Schema

### Operative Activities Table

```sql
CREATE TABLE operative_activities (
  time TIMESTAMPTZ NOT NULL,
  operative_id TEXT NOT NULL,
  archetype TEXT NOT NULL,
  action TEXT NOT NULL,
  destination TEXT,
  metadata JSONB,
  performance_metrics JSONB
);

SELECT create_hypertable('operative_activities', 'time');
```

### Transfer Events Table

```sql
CREATE TABLE transfer_events (
  time TIMESTAMPTZ NOT NULL,
  transfer_id TEXT NOT NULL,
  operative_id TEXT,
  source_destination TEXT NOT NULL,
  target_destination TEXT NOT NULL,
  transfer_type TEXT NOT NULL,
  status TEXT NOT NULL,
  duration_ms INTEGER,
  metadata JSONB
);

SELECT create_hypertable('transfer_events', 'time');
```

### Performance Metrics Table

```sql
CREATE TABLE performance_metrics (
  time TIMESTAMPTZ NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value NUMERIC,
  tags JSONB,
  simulation_id TEXT
);

SELECT create_hypertable('performance_metrics', 'time');
```

## Integration Points

### Operative Activity Logging

- **Trigger Points**: All domain actions and state changes
- **Data Captured**: Operative ID, archetype, action type, destination, metadata
- **Performance Impact**: Minimal overhead with async logging
- **Query Patterns**: Time-range analysis, archetype comparisons

### Transfer Event Recording

- **Trigger Points**: Transfer initiation, completion, and failures
- **Data Captured**: Transfer details, performance metrics, error conditions
- **Performance Impact**: Atomic logging with transaction guarantees
- **Query Patterns**: Transfer success rates, bottleneck analysis

### Metrics Collection

- **System Metrics**: Memory usage, process counts, response times
- **Operative Metrics**: Action success rates, transfer frequencies
- **Simulation Metrics**: Overall performance and health indicators
- **Query Patterns**: Trend analysis, anomaly detection

## Query Optimization Strategies

### Time-Series Queries

- **Continuous Aggregates**: Pre-computed metrics for fast dashboard queries
- **Time Bucketing**: Efficient aggregation by time intervals
- **Retention Policies**: Automatic data aging and compression
- **Indexing Strategy**: Composite indexes on time + operative_id

### Analytics Queries

```sql
-- Operative activity patterns
SELECT
  time_bucket('1 hour', time) as hour,
  archetype,
  action,
  count(*) as action_count
FROM operative_activities
WHERE time > now() - interval '24 hours'
GROUP BY hour, archetype, action
ORDER BY hour;

-- Transfer performance analysis
SELECT
  source_destination,
  target_destination,
  avg(duration_ms) as avg_duration,
  count(*) as transfer_count
FROM transfer_events
WHERE status = 'completed'
  AND time > now() - interval '1 hour'
GROUP BY source_destination, target_destination;
```

## Performance Targets

### Ingestion Performance

- **Events per Second**: Support for 10,000+ events/second
- **Latency**: Sub-10ms write latency for individual events
- **Batch Efficiency**: Optimized batch inserts for high-volume scenarios
- **Concurrent Writers**: Support for multiple simulation processes

### Query Performance

- **Dashboard Queries**: Sub-100ms response for real-time metrics
- **Analytics Queries**: Sub-1s response for complex aggregations
- **Time Range Queries**: Efficient querying across days/weeks of data
- **Concurrent Readers**: Support for multiple dashboard users

## Data Management

### Retention Strategy

- **Active Simulations**: Retain all data for running simulations
- **Recent History**: Keep detailed data for last 7 days
- **Compressed History**: Compress data older than 7 days
- **Archive Policy**: Move very old data to separate archive tables

### Backup and Recovery

- **Continuous Backup**: Real-time backup of simulation data
- **Point-in-Time Recovery**: Ability to restore simulation state
- **Data Export**: CSV/JSON export for external analysis
- **Integrity Checks**: Regular validation of stored data

## Consequences

### Positive

- **Time-Series Performance**: Hypertables provide excellent query performance
- **Scalability**: Handles high-volume simulation event streams
- **Analytics Capability**: Rich querying for simulation analysis
- **Data Persistence**: Reliable storage with backup and recovery

### Negative

- **Storage Requirements**: Time-series data grows rapidly
- **Query Complexity**: Time-series queries require specialized knowledge
- **Maintenance Overhead**: Hypertable management and retention policies
- **Cost**: TimescaleDB licensing and infrastructure costs

## Success Criteria

- [ ] Efficient storage of 10,000+ events per second
- [ ] Sub-100ms query response for dashboard metrics
- [ ] Complete audit trail for all operative activities
- [ ] Successful data retention and compression policies
- [ ] Comprehensive analytics capabilities for simulation data

## Related Decisions

- R25W1900003: Real-time Broadcasting System
- R25W1900004: Web Dashboard Interface
- R25W1900006: Performance Monitoring System
