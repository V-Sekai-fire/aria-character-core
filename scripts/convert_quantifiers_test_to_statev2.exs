#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Quick script to convert the durative actions quantifiers test to StateV2 format

defmodule StateV2Converter do
  def convert_file(input_path, output_path \\ nil) do
    output_path = output_path || input_path
    
    content = File.read!(input_path)
    
    # Convert all State function calls to StateV2 with proper parameter order
    converted = content
    # Convert State references to StateV2
    |> String.replace("alias AriaEngine.State", "alias AriaEngine.StateV2")
    
    # Convert State.new() to StateV2.new()
    |> String.replace("State.new()", "StateV2.new()")
    
    # Convert State.set_fact calls from predicate-subject-fact to subject-predicate-fact
    |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\3\", \"\\2\", \"\\4\")")
    
    # Convert State.get_fact calls from predicate-subject to subject-predicate 
    |> String.replace(~r/State\.get_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.get_fact(\\1, \"\\3\", \"\\2\")")
    
    # Convert State.get_subjects_with_fact calls
    |> String.replace(~r/State\.get_subjects_with_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.get_subjects_with_fact(\\1, \"\\2\", \"\\3\")")
    
    File.write!(output_path, converted)
    IO.puts("Converted #{input_path} to StateV2 format")
  end
end

# Convert the test file
StateV2Converter.convert_file("apps/aria_engine/test/aria_engine/durative_actions_quantifiers_test.exs")
