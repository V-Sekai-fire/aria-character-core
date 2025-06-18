#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Fix effects parameter order to match StateV2's subject-predicate-object format

defmodule EffectsParameterOrderFixer do
  def convert_file(input_path) do
    content = File.read!(input_path)
    
    # Replace effects tuples from {predicate, subject, object} to {subject, predicate, object}
    converted = content
    |> String.replace(~r/\{"activity", "security_npc", "patrol_complete"\}/, "{\"security_npc\", \"activity\", \"patrol_complete\"}")
    |> String.replace(~r/\{"security_status", "building", "secure"\}/, "{\"building\", \"security_status\", \"secure\"}")
    |> String.replace(~r/\{"maintenance_status", "facility", "checked"\}/, "{\"facility\", \"maintenance_status\", \"checked\"}")
    |> String.replace(~r/\{"last_check", "facility", "today"\}/, "{\"facility\", \"last_check\", \"today\"}")
    |> String.replace(~r/\{"activity", "chef", "meal_served"\}/, "{\"chef\", \"activity\", \"meal_served\"}")
    |> String.replace(~r/\{"customer_status", "restaurant", "satisfied"\}/, "{\"restaurant\", \"customer_status\", \"satisfied\"}")
    
    File.write!(input_path, converted)
    IO.puts("Fixed effects parameter order in #{input_path}")
  end
end

# Convert the test file
EffectsParameterOrderFixer.convert_file("apps/aria_engine/test/aria_engine/durative_actions_quantifiers_test.exs")
