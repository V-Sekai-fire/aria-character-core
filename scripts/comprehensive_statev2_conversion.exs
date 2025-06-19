#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Comprehensive conversion of quantifiers test to StateV2 format

defmodule ComprehensiveStateV2Converter do
  def convert_file(input_path) do
    content = File.read!(input_path)
    
    # Step 1: Convert alias
    converted = content
    |> String.replace("alias State", "alias StateV2")
    
    # Step 2: Convert all State function calls to StateV2
    |> String.replace("AriaEngine.StateV2.new()", "StateV2.new()")
    |> String.replace("State.set_fact", "StateV2.set_fact")
    |> String.replace("State.get_fact", "StateV2.get_fact")
    |> String.replace("State.get_subjects_with_fact", "StateV2.get_subjects_with_fact")
    
    # Step 3: Fix StateV2.set_fact parameter order (predicate,subject,object -> subject,predicate,object)
    |> String.replace(~r/StateV2\.set_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\\1, \"\\3\", \"\\2\", \"\\4\")")
    
    # Step 4: Fix StateV2.get_fact parameter order (predicate,subject -> subject,predicate)
    |> String.replace(~r/StateV2\.get_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.get_fact(\\1, \"\\3\", \"\\2\")")
    
    # Step 5: Fix quantifier parameter order in conditions (predicate,object,filter -> filter,predicate,object)
    |> String.replace(~r/\{:exists, "([^"]+)", "([^"]+)", (&[^}]+)\}/, 
                     "{:exists, \\3, \"\\1\", \"\\2\"}")
    |> String.replace(~r/\{:forall, "([^"]+)", "([^"]+)", (&[^}]+)\}/, 
                     "{:forall, \\3, \"\\1\", \"\\2\"}")
    
    # Step 6: Fix effects parameter order (predicate,subject,object -> subject,predicate,object)
    |> String.replace(~r/\{"activity", "([^"]+)", "([^"]+)"\}/, 
                     "{\"\\1\", \"activity\", \"\\2\"}")
    |> String.replace(~r/\{"inventory", "([^"]+)", "([^"]+)"\}/, 
                     "{\"\\1\", \"inventory\", \"\\2\"}")
    |> String.replace(~r/\{"security_status", "([^"]+)", "([^"]+)"\}/, 
                     "{\"\\1\", \"security_status\", \"\\2\"}")
    |> String.replace(~r/\{"maintenance_status", "([^"]+)", "([^"]+)"\}/, 
                     "{\"\\1\", \"maintenance_status\", \"\\2\"}")
    |> String.replace(~r/\{"last_check", "([^"]+)", "([^"]+)"\}/, 
                     "{\"\\1\", \"last_check\", \"\\2\"}")
    |> String.replace(~r/\{"customer_status", "([^"]+)", "([^"]+)"\}/, 
                     "{\"\\1\", \"customer_status\", \"\\2\"}")
    
    File.write!(input_path, converted)
    IO.puts("Completed comprehensive StateV2 conversion for #{input_path}")
  end
end

# Convert the test file
ComprehensiveStateV2Converter.convert_file("apps/aria_engine/test/aria_engine/durative_actions_quantifiers_test.exs")
