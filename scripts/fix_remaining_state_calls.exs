#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Fix remaining State calls in quantifiers test

defmodule FinalStateConverter do
  def convert_file(input_path) do
    content = File.read!(input_path)
    
    # Replace ALL remaining State. calls with StateV2.
    converted = content
    |> String.replace("State.set_fact", "StateV2.set_fact")
    |> String.replace("State.get_fact", "StateV2.get_fact")
    |> String.replace("State.get_subjects_with_fact", "StateV2.get_subjects_with_fact")
    |> String.replace("State.new", "StateV2.new")
    
    File.write!(input_path, converted)
    IO.puts("Fixed all remaining State calls in #{input_path}")
  end
end

# Convert the test file
FinalStateConverter.convert_file("apps/aria_engine/test/aria_engine/durative_actions_quantifiers_test.exs")
