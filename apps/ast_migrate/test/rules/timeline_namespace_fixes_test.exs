# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.TimelineNamespaceFixesTest do
  use ExUnit.Case, async: true
  alias AstMigrate.Rules.TimelineNamespaceFixes

  describe "transform_file_content/1" do
    test "transforms module name from AriaEngine.Timeline to Timeline" do
      input = """
      defmodule AriaEngine.Timeline.IntervalISO8601Test do
        use ExUnit.Case, async: true
        alias Timeline.Interval

        test "example test" do
          assert true
        end
      end
      """

      expected = """
      defmodule Timeline.IntervalISO8601Test do
        use ExUnit.Case, async: true
        alias Timeline.Interval

        test "example test" do
          assert true
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)
      assert String.trim(result) == String.trim(expected)
    end

    test "transforms alias statements from AriaEngine.Timeline to Timeline" do
      input = """
      defmodule Timeline.TimelineBridgeTest do
        use ExUnit.Case, async: true
        alias AriaEngine.Timeline.Bridge
        alias Timeline.Interval

        test "example test" do
          bridge = Bridge.new("test", "2025-01-01T12:00:00Z", :decision)
          assert bridge.id == "test"
        end
      end
      """

      expected = """
      defmodule Timeline.TimelineBridgeTest do
        use ExUnit.Case, async: true
        alias Timeline.Bridge
        alias Timeline.Interval

        test "example test" do
          bridge = Bridge.new("test", "2025-01-01T12:00:00Z", :decision)
          assert bridge.id == "test"
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)
      assert String.trim(result) == String.trim(expected)
    end

    test "transforms doctest statements from AriaEngine.Timeline to Timeline" do
      input = """
      defmodule AriaEngine.Timeline.BridgeTest do
        use ExUnit.Case, async: true
        doctest AriaEngine.Timeline.Bridge
        alias AriaEngine.Timeline.Bridge

        test "example test" do
          assert true
        end
      end
      """

      expected = """
      defmodule Timeline.BridgeTest do
        use ExUnit.Case, async: true
        doctest Timeline.Bridge
        alias Timeline.Bridge

        test "example test" do
          assert true
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)
      assert String.trim(result) == String.trim(expected)
    end

    test "transforms qualified function calls from AriaEngine.Timeline to Timeline" do
      input = """
      defmodule SomeTest do
        use ExUnit.Case

        test "qualified calls" do
          timeline = AriaEngine.Timeline.new()
          result = AriaEngine.Timeline.add_interval(timeline, interval)
          assert AriaEngine.Timeline.consistent?(result)
        end
      end
      """

      expected = """
      defmodule SomeTest do
        use ExUnit.Case

        test "qualified calls" do
          timeline = Timeline.new()
          result = Timeline.add_interval(timeline, interval)
          assert Timeline.consistent?(result)
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)
      assert String.trim(result) == String.trim(expected)
    end

    test "transforms nested module names correctly" do
      input = """
      defmodule AriaEngine.Timeline.Internal.STNTest do
        use ExUnit.Case
        alias AriaEngine.Timeline.Internal.STN
        import AriaEngine.Timeline.Internal.Operations

        test "nested modules" do
          result = AriaEngine.Timeline.Internal.STN.new()
          assert result
        end
      end
      """

      expected = """
      defmodule Timeline.Internal.STNTest do
        use ExUnit.Case
        alias Timeline.Internal.STN
        import Timeline.Internal.Operations

        test "nested modules" do
          result = Timeline.Internal.STN.new()
          assert result
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)
      assert String.trim(result) == String.trim(expected)
    end

    test "handles mixed content with some correct and some incorrect references" do
      input = """
      defmodule AriaEngine.Timeline.MixedTest do
        use ExUnit.Case
        alias Timeline.Interval
        alias AriaEngine.Timeline.Bridge
        doctest AriaEngine.Timeline.Bridge

        test "mixed references" do
          interval = Timeline.Interval.new()
          bridge = AriaEngine.Timeline.Bridge.new("test", "2025-01-01T12:00:00Z", :decision)
          timeline = Timeline.new()
          assert Timeline.consistent?(timeline)
        end
      end
      """

      expected = """
      defmodule Timeline.MixedTest do
        use ExUnit.Case
        alias Timeline.Interval
        alias Timeline.Bridge
        doctest Timeline.Bridge

        test "mixed references" do
          interval = Timeline.Interval.new()
          bridge = Timeline.Bridge.new("test", "2025-01-01T12:00:00Z", :decision)
          timeline = Timeline.new()
          assert Timeline.consistent?(timeline)
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)
      assert String.trim(result) == String.trim(expected)
    end

    test "leaves files with no AriaEngine.Timeline references unchanged" do
      input = """
      defmodule Timeline.STNCapabilitiesTest do
        use ExUnit.Case, async: true
        alias Timeline
        alias Timeline.Interval
        alias Timeline.AgentEntity

        test "no changes needed" do
          timeline = Timeline.new()
          interval = Timeline.Interval.new()
          assert Timeline.consistent?(timeline)
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)
      assert String.trim(result) == String.trim(input)
    end

    test "preserves comments and formatting" do
      input = """
      # Copyright notice
      defmodule AriaEngine.Timeline.CommentTest do
        use ExUnit.Case, async: true
        # This is a comment about the alias
        alias AriaEngine.Timeline.Bridge

        # Test with comments
        test "preserves comments" do
          # Create a bridge
          bridge = Bridge.new("test", "2025-01-01T12:00:00Z", :decision)
          # Assert it works
          assert bridge.id == "test"
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)

      # Should transform the namespace but preserve comments
      assert String.contains?(result, "# Copyright notice")
      assert String.contains?(result, "# This is a comment about the alias")
      assert String.contains?(result, "# Test with comments")
      assert String.contains?(result, "# Create a bridge")
      assert String.contains?(result, "# Assert it works")
      assert String.contains?(result, "defmodule Timeline.CommentTest do")
      assert String.contains?(result, "alias Timeline.Bridge")
    end

    test "handles import statements correctly" do
      input = """
      defmodule TestModule do
        use ExUnit.Case
        import AriaEngine.Timeline
        import AriaEngine.Timeline.Internal.Operations

        test "import transformation" do
          assert true
        end
      end
      """

      expected = """
      defmodule TestModule do
        use ExUnit.Case
        import Timeline
        import Timeline.Internal.Operations

        test "import transformation" do
          assert true
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)
      assert String.trim(result) == String.trim(expected)
    end

    test "handles complex real-world example from bridge_test.exs" do
      input = """
      defmodule AriaEngine.Timeline.BridgeTest do
        use ExUnit.Case, async: true
        doctest AriaEngine.Timeline.Bridge
        alias AriaEngine.Timeline.Bridge

        describe("new/4") do
          test "creates a bridge with required parameters" do
            position = "2025-01-01T12:00:00Z"
            bridge = Bridge.new("test_bridge", position, :decision)
            assert bridge.id == "test_bridge"
            assert bridge.position == position
            assert bridge.type == :decision
            assert bridge.metadata == %{}
          end
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)

      # Should transform module name, doctest, and alias
      assert String.contains?(result, "defmodule Timeline.BridgeTest do")
      assert String.contains?(result, "doctest Timeline.Bridge")
      assert String.contains?(result, "alias Timeline.Bridge")
      # Should preserve the test logic unchanged
      assert String.contains?(result, "bridge = Bridge.new(\"test_bridge\", position, :decision)")
      assert String.contains?(result, "assert bridge.id == \"test_bridge\"")
    end
  end

  describe "validation functions" do
    test "validate_preconditions/1 works with files containing references" do
      # Create temporary files for testing
      content_with_refs = "defmodule AriaEngine.Timeline.Test do\nend"
      content_without_refs = "defmodule Timeline.Test do\nend"

      file_with_refs = "/tmp/test_with_references.exs"
      file_without_refs = "/tmp/test_without_references.exs"

      File.write!(file_with_refs, content_with_refs)
      File.write!(file_without_refs, content_without_refs)

      # Should succeed when files have references
      assert :ok == TimelineNamespaceFixes.validate_preconditions([file_with_refs])

      # Should fail when no files have references
      assert {:error, _} = TimelineNamespaceFixes.validate_preconditions([file_without_refs])

      File.rm!(file_with_refs)
      File.rm!(file_without_refs)
    end

    test "transform_file/1 handles file reading and transformation" do
      # Create a temporary file with AriaEngine.Timeline references
      content = "defmodule AriaEngine.Timeline.Test do\n  alias AriaEngine.Timeline.Bridge\nend"
      file_path = "/tmp/test_transform_file.exs"
      File.write!(file_path, content)

      {:ok, result} = TimelineNamespaceFixes.transform_file(file_path)

      # Should transform the content
      assert String.contains?(result, "defmodule Timeline.Test do")
      assert String.contains?(result, "alias Timeline.Bridge")

      File.rm!(file_path)
    end
  end

  describe "transformation counting" do
    test "counts transformations correctly" do
      input = """
      defmodule AriaEngine.Timeline.Test do
        alias AriaEngine.Timeline.Bridge
        doctest AriaEngine.Timeline.Bridge

        def test do
          AriaEngine.Timeline.new()
        end
      end
      """

      {:ok, result} = TimelineNamespaceFixes.transform_file_content(input)

      # Should have transformed 4 references:
      # 1. Module name
      # 2. Alias
      # 3. Doctest
      # 4. Qualified call
      original_count = Regex.scan(~r/AriaEngine\.Timeline/, input) |> length()
      result_count = Regex.scan(~r/AriaEngine\.Timeline/, result) |> length()

      assert original_count == 4
      assert result_count == 0
    end
  end
end