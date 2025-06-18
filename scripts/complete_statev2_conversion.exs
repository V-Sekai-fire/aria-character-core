#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Complete conversion of quantifiers test to StateV2 format

defmodule CompleteStateV2Converter do
  def convert_file(input_path) do
    content = File.read!(input_path)
    
    # Replace all State.set_fact calls with StateV2.set_fact and parameter reordering
    converted = content
    |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\3\", \"\\2\", \"\\4\")")
    
    # Replace any remaining State.get_fact calls  
    |> String.replace(~r/State\.get_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.get_fact(\\1, \"\\3\", \"\\2\")")
    
    File.write!(input_path, converted)
    IO.puts("Completed StateV2 conversion for #{input_path}")
  end
end

# Convert the test file
CompleteStateV2Converter.convert_file("apps/aria_engine/test/aria_engine/durative_actions_quantifiers_test.exs")
