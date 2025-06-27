# R25W117C369: Standardize Local Timezone ISO 8601 DateTime Format

<!-- @adr_serial R25W117C369 -->

## Status

Active (June 23, 2025)

## Context

The project currently has inconsistent datetime handling across different applications and modules. Some areas use UTC timestamps (Zulu time), others use local time without timezone information, and some use system-relative timestamps that produce negative or meaningless values.

### Current Problems

- **Inconsistent formats**: Mix of UTC, local time, and system-relative timestamps
- **Lost timezone context**: UTC timestamps lose local context for debugging and user experience
- **Debugging difficulties**: Hard to correlate log events with local system events
- **User confusion**: Times displayed in UTC when users expect local time
- **System errors**: Negative timestamps from `System.monotonic_time/1` usage
- **API inconsistency**: Duration parameters use raw integers instead of ISO 8601 format

### Examples of Current Issues

```elixir
# Problem: System-relative time producing negative values
generation_time: -576460751187

# Problem: UTC time losing local context
"2025-06-24T06:15:24.123456Z"  # User sees 6 AM when it's actually 11 PM locally

# Problem: No timezone information
"2025-06-23T23:15:24.123456"  # Ambiguous timezone

# Problem: API parameter inconsistency
options = %{time_horizon: 20}  # Should be "PT20S"
```

## Decision

**Standardize on local timezone ISO 8601 format with timezone offset for all datetime and duration handling across the project.**

### Primary Standard

- **Format**: ISO 8601 Extended format with local timezone offset
- **Implementation**: Use Timex for consistent datetime handling
- **Example**: `"2025-06-23T23:15:24.123456-07:00"` (Vancouver timezone)

### Implementation Pattern

```elixir
# Preferred approach everywhere
datetime = Timex.now() |> Timex.format!("{ISO:Extended}")

# Duration calculation with microseconds precision
defp calculate_duration(start_iso, end_iso) do
  start_dt = Timex.parse!(start_iso, "{ISO:Extended}")
  end_dt = Timex.parse!(end_iso, "{ISO:Extended}")
  
  # Use microseconds as Timex's most precise integer duration element
  duration_microseconds = Timex.diff(end_dt, start_dt, :microseconds)
  duration_seconds = duration_microseconds / 1_000_000
  "PT#{duration_seconds}S"
end
```

### Exception Policy

**Only use UTC/Zulu time when:**

- The local timezone IS UTC (server running in UTC timezone)
- Explicit cross-timezone coordination is required
- Database internal storage (but display in local timezone)

**Never use:**

- `System.monotonic_time/1` for user-facing timestamps
- `DateTime.utc_now()` unless local timezone is UTC
- Timezone-naive datetime strings

## Implementation Plan

### Phase 1: New Code Standard (Immediate)

- [ ] All new datetime fields use local timezone ISO 8601 format
- [ ] Update coding standards documentation
- [ ] Add Timex import to all modules handling datetime

### Phase 2: Critical Fixes (Week 1)

- [x] Fix MiniZinc ProblemGenerator metadata timestamps (completed)
  - [x] Core datetime tracking implemented with ISO 8601 format
  - [x] Add missing Timex dependency to aria_minizinc mix.exs
  - [x] Fix duration calculation to use microseconds precision
  - [x] Replace remaining System.monotonic_time usage in template generation
- [ ] Standardize API duration parameters (in progress)
  - [ ] Add duration validation to ProblemGenerator options
  - [ ] Update test cases to use ISO 8601 duration format
  - [ ] Create duration parsing helper functions
  - [ ] Update type specifications for duration parameters
- [ ] Update logging configuration for local timezone
- [x] Fix any negative timestamp issues (resolved with ISO 8601 implementation)

### Phase 3: Application Audit (Week 2-3)

- [ ] Audit all applications for datetime usage:
  - [ ] aria_minizinc
  - [ ] aria_hybrid_planner
  - [ ] aria_scheduler
  - [ ] aria_engine_core
  - [ ] aria_temporal_planner
  - [ ] Other applications

### Phase 4: Migration (Week 4)

- [ ] Migrate existing UTC-only timestamps to local timezone format
- [ ] Update API documentation
- [ ] Update database schema if needed
- [ ] Test cross-timezone compatibility

## Application Areas

### All datetime and duration fields in

- **Logging**: All log timestamps
- **Database records**: created_at, updated_at, processed_at
- **API responses**: All datetime fields
- **API parameters**: time_horizon, max_duration, timeout values
- **Metadata**: generation_time, processing_time, execution_time
- **Audit trails**: User actions, system events
- **Scheduling**: Task execution times, deadlines
- **Problem generation**: Start, end, duration timestamps
- **Test results**: Test execution times
- **Performance metrics**: Timing measurements

## Benefits

### User Experience

- **Local context**: Times make sense to local users and developers
- **Debugging clarity**: Easy correlation with local system events
- **Intuitive timestamps**: No mental timezone conversion required

### Technical Benefits

- **Global compatibility**: ISO 8601 with timezone is universally parseable
- **Audit compliance**: Clear temporal tracking with timezone context
- **Consistent format**: Single standard across entire project
- **Proper duration calculation**: Accurate timing with timezone handling

### Development Benefits

- **Easier debugging**: Log timestamps match local system time
- **Better testing**: Test execution times in local context
- **Clear documentation**: Timestamps in documentation match local time

## Consequences

### Positive

- **Consistent datetime handling** across all applications
- **Improved debugging experience** with local timezone context
- **Better user experience** with intuitive timestamps
- **Standards compliance** with ISO 8601 format
- **Future-proof** timezone handling

### Migration Requirements

- **Code updates** needed across multiple applications
- **Documentation updates** for API and coding standards
- **Testing** required for timezone edge cases
- **Training** for team on new datetime standards

### Potential Challenges

- **Migration effort** for existing codebase
- **Cross-timezone testing** complexity
- **Database migration** if schema changes needed

## Success Criteria

- [ ] All new datetime fields use local timezone ISO 8601 format
- [ ] All duration parameters use ISO 8601 duration format
- [ ] No more negative or system-relative timestamps
- [ ] Consistent datetime format across all applications
- [ ] API parameter validation for duration strings
- [ ] Improved debugging experience with local timezone context
- [ ] Documentation updated with new standards
- [ ] All applications have Timex dependency where datetime handling is used
- [ ] Duration calculations use microseconds precision for accuracy
- [ ] Template generation uses ISO 8601 local timezone format
- [ ] No backward compatibility for integer duration parameters

## Related ADRs

- **R25W063FA55**: Canonical Time Unit Seconds and STN Units
- **R25W09080DB**: Fix Duration Handling Precision Loss

## Implementation Notes

### Timex Usage

```elixir
# Standard datetime capture
start_time = Timex.now() |> Timex.format!("{ISO:Extended}")

# Duration calculation with microseconds precision
duration_microseconds = Timex.diff(end_dt, start_dt, :microseconds)
duration_seconds = duration_microseconds / 1_000_000
duration_iso = "PT#{duration_seconds}S"

# Parsing existing timestamps
parsed_dt = Timex.parse!(timestamp, "{ISO:Extended}")
```

### Type Specifications

```elixir
@type iso8601_datetime :: String.t()  # "2025-06-23T23:15:24.123456-07:00"
@type iso8601_duration :: String.t()  # "PT1.234S"
```

### API Parameter Standardization

```elixir
# Before (inconsistent)
options = %{time_horizon: 20, max_steps: 100}

# After (ISO 8601 compliant)
options = %{time_horizon: "PT20S", max_duration: "PT100S"}

# Duration validation function
defp validate_duration(duration_string) do
  case Timex.Duration.parse(duration_string) do
    {:ok, _duration} -> :ok
    {:error, reason} -> {:error, "Invalid duration format: #{reason}"}
  end
end
```

### No Backward Compatibility Policy

**Breaking Change**: All duration parameters must use ISO 8601 format. Integer values for time/duration parameters are no longer supported to ensure API consistency and eliminate ambiguity.

This ADR establishes the foundation for consistent, local-timezone-aware datetime handling across the entire project.
