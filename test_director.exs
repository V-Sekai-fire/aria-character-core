# Test script for the new director tool
IO.puts("Testing director tool...")

# Test getting tool definitions
IO.puts("\n=== Testing Tool Definitions ===")
definitions = AriaEngine.MCPTools.get_all_tools()
IO.inspect(definitions, label: "All tool definitions", limit: :infinity)

# Test director tool call
IO.puts("\n=== Testing Director Tool Call ===")
params = %{
  "template" => "tri_zone_integration",
  "narrative_mode" => true
}

result = AriaEngine.MCPTools.handle_tool_call(:director, params)
IO.inspect(result, label: "Director tool result", limit: :infinity)

IO.puts("\n=== Director Tool Test Complete ===")
