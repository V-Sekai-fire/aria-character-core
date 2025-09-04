defmodule AriaInteractivityTest do
  use ExUnit.Case
  doctest AriaInteractivity

  test "app structure is correct" do
    # Test that the app has proper structure
    assert File.dir?("apps/aria_interactivity")
    assert File.dir?("apps/aria_interactivity/lib")
    assert File.dir?("apps/aria_interactivity/test")
    assert File.dir?("apps/aria_interactivity/decisions")
    assert File.exists?("apps/aria_interactivity/mix.exs")
    assert File.exists?("apps/aria_interactivity/README.md")
  end

  test "dependencies are configured" do
    # Test that mix.exs contains required dependencies
    mix_content = File.read!("apps/aria_interactivity/mix.exs")
    assert String.contains?(mix_content, "aria_gltf")
    assert String.contains?(mix_content, "aria_hybrid_planner")
    assert String.contains?(mix_content, "https://github.com/V-Sekai-fire/aria-hybrid-planner")
  end

  test "parse_specification returns error when not implemented" do
    assert {:error, :not_implemented} = AriaInteractivity.parse_specification()
  end

  test "graph_to_problem returns error when not implemented" do
    assert {:error, :not_implemented} = AriaInteractivity.graph_to_problem(%{})
  end

  test "domain defines math operations" do
    # Red: This test should fail initially - domain module doesn't exist yet
    assert function_exported?(AriaInteractivity.Domain, :math_add, 2)
    assert function_exported?(AriaInteractivity.Domain, :math_subtract, 2)
    assert function_exported?(AriaInteractivity.Domain, :math_multiply, 2)
  end

  test "domain defines control flow operations" do
    # Red: This test should fail initially
    assert function_exported?(AriaInteractivity.Domain, :flow_sequence, 1)
    assert function_exported?(AriaInteractivity.Domain, :flow_branch, 2)
  end

  test "domain defines state operations" do
    # Red: This test should fail initially
    assert function_exported?(AriaInteractivity.Domain, :variable_set, 2)
    assert function_exported?(AriaInteractivity.Domain, :pointer_get, 1)
  end
end
