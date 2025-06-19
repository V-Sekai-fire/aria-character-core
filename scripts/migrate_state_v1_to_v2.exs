#!/usr/bin/env elixir

# Script to migrate from legacy State to AriaEngine.StateV2
# This script will update all references to use the new StateV2 format

defmodule StateV1ToV2Migration do
  @moduledoc """
  Migrates all references from legacy State module to AriaEngine.StateV2.
  
  Changes:
  - AriaEngine.StateV2.new() -> AriaEngine.StateV2.new()
  - AriaEngine.StateV2.get_fact() -> AriaEngine.StateV2.get_fact()
  - AriaEngine.StateV2.set_fact() -> AriaEngine.StateV2.set_fact()
  - All other State.* calls -> AriaEngine.StateV2.*
  - Type annotations: AriaEngine.StateV2.t() -> AriaEngine.StateV2.t()
  - Pattern matches: %AriaEngine.StateV2{} -> %AriaEngine.StateV2{}
  """

  def run do
    IO.puts("Starting State v1 to StateV2 migration...")
    
    # Get all .ex and .exs files
    files = find_elixir_files()
    
    IO.puts("Found #{length(files)} Elixir files to process")
    
    # Process each file
    Enum.each(files, &process_file/1)
    
    IO.puts("Migration completed!")
    IO.puts("\nNext steps:")
    IO.puts("1. Run tests to verify migration")
    IO.puts("2. Delete lib/aria_engine/state.ex")
    IO.puts("3. Remove legacy conversion functions from StateV2")
  end
  
  defp find_elixir_files do
    Path.wildcard("lib/**/*.ex") ++ 
    Path.wildcard("test/**/*.exs") ++
    Path.wildcard("scripts/**/*.exs")
  end
  
  defp process_file(file_path) do
    content = File.read!(file_path)
    updated_content = migrate_content(content)
    
    if content != updated_content do
      IO.puts("Updating #{file_path}")
      File.write!(file_path, updated_content)
    end
  end
  
  defp migrate_content(content) do
    content
    # Replace State module calls with AriaEngine.StateV2
    |> String.replace(~r/State\.new\(\)/, "AriaEngine.StateV2.new()")
    |> String.replace(~r/State\.new\(([^)]+)\)/, "AriaEngine.StateV2.new(\\1)")
    |> String.replace(~r/State\.get_fact\(/, "AriaEngine.StateV2.get_fact(")
    |> String.replace(~r/State\.set_fact\(/, "AriaEngine.StateV2.set_fact(")
    |> String.replace(~r/State\.remove_fact\(/, "AriaEngine.StateV2.remove_fact(")
    |> String.replace(~r/State\.has_subject\?\(/, "AriaEngine.StateV2.has_subject?(")
    |> String.replace(~r/State\.has_subject_variable\?\(/, "AriaEngine.StateV2.has_subject_variable?(")
    |> String.replace(~r/State\.get_subjects\(/, "AriaEngine.StateV2.get_subjects(")
    |> String.replace(~r/State\.get_subject_properties\(/, "AriaEngine.StateV2.get_subject_properties(")
    |> String.replace(~r/State\.to_triples\(/, "AriaEngine.StateV2.to_triples(")
    |> String.replace(~r/State\.from_triples\(/, "AriaEngine.StateV2.from_triples(")
    |> String.replace(~r/State\.merge\(/, "AriaEngine.StateV2.merge(")
    |> String.replace(~r/State\.copy\(/, "AriaEngine.StateV2.copy(")
    |> String.replace(~r/State\.matches\?\(/, "AriaEngine.StateV2.matches_exactly?(")
    |> String.replace(~r/State\.exists\?\(/, "AriaEngine.StateV2.exists?(")
    |> String.replace(~r/State\.forall\?\(/, "AriaEngine.StateV2.forall?(")
    |> String.replace(~r/State\.get_subjects_with_fact\(/, "AriaEngine.StateV2.get_subjects_with_fact(")
    |> String.replace(~r/State\.get_subjects_with_predicate\(/, "AriaEngine.StateV2.get_subjects_with_predicate(")
    |> String.replace(~r/State\.evaluate_condition\(/, "AriaEngine.StateV2.evaluate_condition(")
    
    # Replace type annotations
    |> String.replace(~r/State\.t\(\)/, "AriaEngine.StateV2.t()")
    |> String.replace(~r/State\.fact_value\(\)/, "AriaEngine.StateV2.fact_value()")
    |> String.replace(~r/State\.predicate\(\)/, "AriaEngine.StateV2.predicate()")
    |> String.replace(~r/State\.subject\(\)/, "AriaEngine.StateV2.subject()")
    
    # Replace pattern matches and struct references
    |> String.replace(~r/%State\{/, "%AriaEngine.StateV2{")
    |> String.replace(~r/%State\{\}/, "%AriaEngine.StateV2{}")
    
    # Replace function parameter patterns
    |> String.replace(~r/\(%State\{\} = state/, "(%AriaEngine.StateV2{} = state")
    |> String.replace(~r/\(%State\{/, "(%AriaEngine.StateV2{")
    
    # Replace type specs that use bare State
    |> String.replace(~r/@type\s+state\s*::\s*State\.t\(\)/, "@type state :: AriaEngine.StateV2.t()")
    |> String.replace(~r/State\.t\(\)\s*\|/, "AriaEngine.StateV2.t() |")
    |> String.replace(~r/\|\s*State\.t\(\)/, "| AriaEngine.StateV2.t()")
    |> String.replace(~r/,\s*State\.t\(\)/, ", AriaEngine.StateV2.t()")
    |> String.replace(~r/\(\s*State\.t\(\)/, "(AriaEngine.StateV2.t()")
    |> String.replace(~r/State\.t\(\)\s*\)/, "AriaEngine.StateV2.t())")
    
    # Handle function specs with AriaEngine.StateV2.t()
    |> String.replace(~r/@spec\s+([^:]+):\s*State\.t\(\)/, "@spec \\1: AriaEngine.StateV2.t()")
    |> String.replace(~r/\s*->\s*State\.t\(\)/, " -> AriaEngine.StateV2.t()")
    |> String.replace(~r/State\.t\(\)\s*->/, "AriaEngine.StateV2.t() ->")
    
    # Handle alias statements (remove State alias, it will use full module name)
    |> String.replace(~r/alias State\s*#.*\n/, "")
    |> String.replace(~r/alias State\n/, "")
    
    # Handle documentation examples
    |> String.replace(~r/state = State\.new\(\)/, "state = AriaEngine.StateV2.new()")
    |> String.replace(~r/State\.get_fact\(state,/, "AriaEngine.StateV2.get_fact(state,")
    |> String.replace(~r/State\.exists\?\(state,/, "AriaEngine.StateV2.exists?(state,")
    |> String.replace(~r/State\.forall\?\(state,/, "AriaEngine.StateV2.forall?(state,")
    |> String.replace(~r/State\.evaluate_condition\(state,/, "AriaEngine.StateV2.evaluate_condition(state,")
    |> String.replace(~r/State\.get_subjects_with_fact\(state,/, "AriaEngine.StateV2.get_subjects_with_fact(state,")
    |> String.replace(~r/State\.get_subjects_with_predicate\(state,/, "AriaEngine.StateV2.get_subjects_with_predicate(state,")
  end
end

# Run the migration
StateV1ToV2Migration.run()
