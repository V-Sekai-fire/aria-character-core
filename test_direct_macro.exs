# Test direct macro call
IO.puts("Testing direct macro call...")

defmodule DirectMacroTest do
  require AriaCore.ActionAttributes

  IO.puts("DEBUG: About to call action macro directly")
  AriaCore.ActionAttributes.action(duration: "PT5M")
  IO.puts("DEBUG: Direct macro call completed")

  def test_action(_state, []) do
    IO.puts("Test action called")
    %{}
  end
end

IO.puts("Direct macro test completed")
