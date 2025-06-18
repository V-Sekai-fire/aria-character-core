#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Fix StateV2.set_fact parameter order in action functions and test setup

defmodule ActionFunctionParameterFixer do
  def convert_file(input_path) do
    content = File.read!(input_path)
    
    # Fix all StateV2.set_fact calls to use subject-predicate-object order
    converted = content
    # Fix test setup calls
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"type",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\2\", \"type\", \"\\3\")")
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"status",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\2\", \"status\", \"\\3\")")
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"activity",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\2\", \"activity\", \"\\3\")")
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"location",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\2\", \"location\", \"\\3\")")
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"security_status",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\2\", \"security_status\", \"\\3\")")
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"maintenance_status",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\2\", \"maintenance_status\", \"\\3\")")
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"last_check",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\2\", \"last_check\", \"\\3\")")
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"customer_status",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\2\", \"customer_status\", \"\\3\")")
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"inventory",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\2\", \"inventory\", \"\\3\")")
    
    File.write!(input_path, converted)
    IO.puts("Fixed action function parameters in #{input_path}")
  end
end

# Convert the test file
ActionFunctionParameterFixer.convert_file("apps/aria_engine/test/aria_engine/durative_actions_quantifiers_test.exs")
