# Debug script for converting State to StateV2 in test files
# Usage: mix run scripts/debug_state_migration.exs

defmodule StateMigrationDebug do
  def convert_durative_actions_test do
    IO.puts("=== Converting DurativeActionsTest to StateV2 ===")
    
    file_path = "test/aria_engine/durative_actions_test.exs"
    
    # Read the current file
    {:ok, content} = File.read(file_path)
    
    # Convert all State references to StateV2
    updated_content = content
    |> String.replace("State.new()", "StateV2.new()")
    |> convert_state_calls_to_statev2()
    
    # Write back to file
    File.write!(file_path, updated_content)
    
    IO.puts("✅ Conversion complete!")
    IO.puts("Updated file: #{file_path}")
  end
  
  defp convert_state_calls_to_statev2(content) do
    content
    # Convert all State. calls to StateV2. first
    |> String.replace("State.", "StateV2.")
    # Then fix the parameter order for set_fact and get_fact
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)",\s*([^)]+)\)/,
                     "StateV2.set_fact(\\1, \"\\3\", \"\\2\", \\4)")
    |> String.replace(~r/StateV2\.get_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)"\)/,
                     "StateV2.get_fact(\\1, \"\\3\", \"\\2\")")
  end
  
  def test_conversion do
    IO.puts("=== Testing State to StateV2 conversion patterns ===")
    
    test_cases = [
      "State.set_fact(\"health_status\", \"robot\", :healthy)",
      "State.get_fact(state, \"battery_level\", \"robot\")",
      "State.set_fact(state, \"door_open\", \"main_door\", false)"
    ]
    
    Enum.each(test_cases, fn test_case ->
      IO.puts("Original: #{test_case}")
      converted = convert_state_calls_to_statev2(test_case)
      IO.puts("Converted: #{converted}")
      IO.puts("---")
    end)
  end
end

# Run the conversion
StateMigrationDebug.convert_durative_actions_test()
