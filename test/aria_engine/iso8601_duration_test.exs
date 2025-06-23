# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ISO8601DurationTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Timeline.Interval
  alias AriaEngine.Domain
  alias AriaEngine.SoftwareDevelopment

  describe "ISO 8601 duration support" do
    test "creates floating duration intervals from ISO 8601 strings" do
      interval = Interval.from_iso8601_duration("PT8H")

      assert interval.start_time == nil
      assert interval.end_time == nil
      assert interval.metadata.iso8601_duration == "PT8H"
      assert interval.metadata.floating_duration == true
    end

    test "software development domain builds with ISO 8601 durations" do
      domain = SoftwareDevelopment.Domain.build()

      # Verify domain was created successfully
      assert domain.name == "software_development"

      # Verify actions exist
      assert Domain.has_action?(domain, :implement_module)
      assert Domain.has_action?(domain, :test_implementation)

      # Verify action metadata contains floating duration intervals
      implement_metadata = Domain.get_action_metadata(domain, :implement_module)
      assert %Interval{} = implement_metadata.duration
      assert implement_metadata.duration.metadata.iso8601_duration == "PT8H"
      assert implement_metadata.duration.metadata.floating_duration == true

      test_metadata = Domain.get_action_metadata(domain, :test_implementation)
      assert %Interval{} = test_metadata.duration
      assert test_metadata.duration.metadata.iso8601_duration == "PT4H"
      assert test_metadata.duration.metadata.floating_duration == true
    end

    test "various ISO 8601 duration formats are supported" do
      # Test different duration formats
      durations = [
        # 1 hour
        "PT1H",
        # 2 hours 30 minutes
        "PT2H30M",
        # 45 minutes
        "PT45M",
        # 8 hours
        "PT8H",
        # 16 hours
        "PT16H"
      ]

      for duration_str <- durations do
        interval = Interval.from_iso8601_duration(duration_str)
        assert interval.metadata.iso8601_duration == duration_str
        assert interval.metadata.floating_duration == true
        assert interval.start_time == nil
        assert interval.end_time == nil
      end
    end
  end
end
