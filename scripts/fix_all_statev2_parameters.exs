#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Fix ALL StateV2.set_fact parameter order issues in the test file

defmodule StateV2ParameterFixer do
  def fix_test_file() do
    file_path = "apps/aria_engine/test/aria_engine/durative_actions_quantifiers_test.exs"
    content = File.read!(file_path)
    
    # Fix all remaining StateV2.set_fact calls to use (subject, predicate, object) order
    fixed_content = content
    # Fix remaining calls in the test setup
    |> String.replace(~r/StateV2\.set_fact\("type",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\"\\1\", \"type\", \"\\2\")")
    |> String.replace(~r/StateV2\.set_fact\("status",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\"\\1\", \"status\", \"\\2\")")
    |> String.replace(~r/StateV2\.set_fact\("activity",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\"\\1\", \"activity\", \"\\2\")")
    |> String.replace(~r/StateV2\.set_fact\("maintenance_status",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\"\\1\", \"maintenance_status\", \"\\2\")")
    |> String.replace(~r/StateV2\.set_fact\("last_check",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\"\\1\", \"last_check\", \"\\2\")")
    |> String.replace(~r/StateV2\.set_fact\("customer_status",\s*"([^"]+)",\s*"([^"]+)"\)/, 
                     "StateV2.set_fact(\"\\1\", \"customer_status\", \"\\2\")")
    
    File.write!(file_path, fixed_content)
    IO.puts("Fixed all StateV2.set_fact parameter orders in #{file_path}")
  end
end

StateV2ParameterFixer.fix_test_file()
