# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Minimal test to isolate the @action attribute issue
IO.puts("Starting minimal test...")

defmodule MinimalTest do
  # Test if the basic module compilation works
  def test_function do
    IO.puts("Basic function works")
  end
end

IO.puts("Basic module compiled successfully")

# Now test with AriaCore.ActionAttributes directly
defmodule AttributeTest do
  use AriaCore.ActionAttributes

  IO.puts("DEBUG: About to set @action attribute")
  @action duration: "PT5M"
  IO.puts("DEBUG: @action attribute set, about to define function")
  def test_action(_state, []) do
    IO.puts("Test action called")
    %{}
  end
  IO.puts("DEBUG: Function defined")
end

IO.puts("ActionAttributes module compiled successfully")

# Test the metadata functions
try do
  metadata = AttributeTest.__action_metadata__()
  IO.puts("✅ Action metadata: #{inspect(metadata)}")
rescue
  e -> IO.puts("❌ Action metadata error: #{inspect(e)}")
end
