# AriaTimelineIntervals

A focused Elixir application for temporal interval operations and Allen's Interval Algebra.

## Overview

AriaTimelineIntervals provides a comprehensive set of tools for working with temporal intervals, including:

- **Interval Management**: Create, validate, and manipulate temporal intervals with DateTime precision
- **Allen's Interval Algebra**: Complete implementation of all 13 Allen relations for temporal reasoning
- **Time Conversion**: Utilities for converting between different time units and formats
- **Timeline Construction**: Build and manage timelines from collections of intervals
- **Timeline Segmentation**: Segment timelines based on duration, overlaps, and gaps

## Key Features

### Interval Operations
- Create intervals with DateTime precision and timezone support
- Validate interval correctness and time ordering
- Calculate durations in multiple time units
- Check containment and overlap relationships

### Allen's Interval Algebra
- All 13 Allen relations: before, after, meets, overlaps, during, contains, etc.
- Temporal relationship detection between intervals
- Support for complex temporal reasoning patterns

### Time Conversion
- Convert between seconds, milliseconds, and DateTime formats
- Maintain microsecond precision for accurate temporal calculations
- Comprehensive error handling and validation

### Timeline Management
- Build timelines from interval collections
- Sort and validate intervals automatically
- Merge multiple timelines with metadata preservation
- Calculate timeline bounds and statistics

### Timeline Segmentation
- Segment by fixed duration windows
- Group overlapping intervals
- Detect and analyze gaps between intervals
- Create segments based on temporal patterns

## Usage Examples

### Basic Interval Operations

```elixir
alias AriaTimelineIntervals.Interval

# Create an interval
start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
interval = Interval.new(start_time, end_time)

# Get duration in different units
Interval.duration_ms(interval)        # 7200000 milliseconds
Interval.duration_seconds(interval)   # 7200.0 seconds
Interval.duration_in_unit(interval, :hour)  # 2 hours
```

### Allen's Interval Algebra

```elixir
alias AriaTimelineIntervals.{Interval, AllenRelations}

# Create two intervals
interval1 = Interval.new(start1, end1)
interval2 = Interval.new(start2, end2)

# Check relationships
AllenRelations.before?(interval1, interval2)
AllenRelations.overlaps?(interval1, interval2)
AllenRelations.relation(interval1, interval2)  # Returns the specific relation
```

### Timeline Construction

```elixir
alias AriaTimelineIntervals.{Interval, TimelineBuilder}

intervals = [interval1, interval2, interval3]
timeline = TimelineBuilder.build(intervals, sort: true, validate: true)

# Timeline includes bounds, metadata, and sorted intervals
timeline.start_time  # Earliest start time
timeline.end_time    # Latest end time
timeline.intervals   # Sorted and validated intervals
```

### Timeline Segmentation

```elixir
alias AriaTimelineIntervals.TimelineSegmenter

# Segment by 1-hour windows
segments = TimelineSegmenter.segment_by_duration(intervals, 3600)

# Group overlapping intervals
overlap_groups = TimelineSegmenter.segment_by_overlaps(intervals)

# Find gaps between intervals
gaps = TimelineSegmenter.find_gaps(intervals)
```

## Architecture

This application is designed as a focused, modular component within the Aria Character Core umbrella project. It provides:

- **Clean API**: Simple, consistent interfaces for temporal operations
- **Type Safety**: Comprehensive typespecs for all public functions
- **Error Handling**: Robust validation and error reporting
- **Performance**: Efficient algorithms for temporal calculations
- **Extensibility**: Modular design for easy extension and customization

## Dependencies

- **Elixir**: Core language features for functional programming
- **DateTime**: Built-in DateTime support with timezone handling
- **Crypto**: For generating unique interval IDs

## Testing

The application includes comprehensive doctests and unit tests covering:

- All interval operations and edge cases
- Complete Allen relation test suite
- Time conversion accuracy and error handling
- Timeline construction and validation
- Segmentation algorithms and boundary conditions

Run tests with:

```bash
mix test
```

## Integration

AriaTimelineIntervals is designed to integrate seamlessly with other Aria Character Core applications:

- **AriaEngine**: Provides temporal reasoning for game state management
- **AriaFlow**: Supports workflow timing and scheduling
- **AriaTimeline**: Extends with additional timeline features

## License

Copyright (c) 2025-present K. S. Ernest (iFire) Lee  
SPDX-License-Identifier: MIT
