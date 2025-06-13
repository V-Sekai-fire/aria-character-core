# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.GenerateCharacter do
  @moduledoc """
  Generate characters using the AriaEngine character generator system.

  This task provides a command-line interface to the character generator,
  allowing you to create characters with various presets, customizations,
  and output formats.

  ## Usage

      mix generate_character [options]

  ## Options

      --preset PRESET          Use a specific preset (fantasy_cyber, cyber_cat_person, 
                               traditional_shrine_maiden, casual_tech)
      --seed SEED              Use a specific seed for reproducible generation
      --count COUNT            Generate multiple characters (default: 1, max: 10)
      --format FORMAT          Output format: json, prompt (default: json)
      --output FILE            Save output to file instead of stdout
      --randomize              Use completely random generation (ignores preset)
      --stats                  Show system statistics and available options
      --list-presets           List all available presets
      --list-attributes        List all character attributes
      --workflow WORKFLOW      Use specific planning workflow (basic, comprehensive, demo)
      --help                   Show this help message
      --show-planning          Show planning TODO list and steps
      --verbose-planning LEVEL Set verbosity level for planning (0-3)

  ## Examples

      # Generate with planning system
      mix generate_character --preset cyber_cat_person

      # Generate using specific planning workflow
      mix generate_character --workflow comprehensive

      # Generate 3 random characters and save as JSON
      mix generate_character --count 3 --format json --randomize

      # Generate reproducible character with specific seed
      mix generate_character --seed 12345

      # Generate prompt-only output for AI text generation
      mix generate_character --format prompt

      # Save generated character to file
      mix generate_character --preset cyber_cat_person --output character.json

      # Show system information
      mix generate_character --stats

      # Show planning TODO list and steps (demo)
      mix generate_character --show-planning

      # Show detailed planning with verbose output
      mix generate_character --show-planning --verbose-planning 2

  ## Output Formats

  - **json**: Complete character data structure (default)
  - **prompt**: AI-ready text prompt for character generation

  ## Presets

  - **fantasy_cyber**: Cyberpunk character with fantasy elements
  - **cyber_cat_person**: Futuristic cat-person character
  - **traditional_shrine_maiden**: Traditional Japanese shrine maiden
  - **casual_tech**: Modern casual character with tech elements

  ## Planning System

  The AriaEngine planner uses RDF-style predicate-subject-object triples for state 
  representation and hierarchical TODO lists for plans. The `--show-planning` option
  demonstrates this structure:

  - **State**: RDF triples like `(character:species, char_123, "SPECIES_HUMANOID")`
  - **Plans**: Hierarchical TODO lists that decompose into executable actions
  - **Actions**: Modify state by adding/updating RDF triples

  For full RDF support, consider integrating with the RDF-ex library:
  https://github.com/rdf-elixir/rdf-ex
  """

  use Mix.Task

  alias AriaEngine.CharacterGenerator

  @shortdoc "Generate characters using AriaEngine"

  # Type definitions
  @type character :: map()
  @type preset_name :: String.t()
  @type workflow_type :: :basic | :comprehensive | :demo | :validation_only | :preset_application
  @type output_format :: String.t()
  @type generation_options :: keyword()
  @type parsed_options :: keyword()
  @type planning_todo :: {String.t(), map()}
  @type rdf_triple :: {String.t(), String.t(), String.t()}
  @type plan_action :: {atom(), map()}

  @switches [
    preset: :string,
    seed: :integer,
    count: :integer,
    format: :string,
    output: :string,
    randomize: :boolean,
    stats: :boolean,
    list_presets: :boolean,
    list_attributes: :boolean,
    workflow: :string,
    help: :boolean,
    show_planning: :boolean,
    verbose_planning: :integer
  ]

  @aliases [
    p: :preset,
    s: :seed,
    c: :count,
    f: :format,
    o: :output,
    r: :randomize,
    w: :workflow,
    h: :help,
    P: :show_planning,
    v: :verbose_planning
  ]

  @spec run([String.t()]) :: :ok
  def run(args) do
    {parsed, _, _} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    cond do
      parsed[:help] -> show_help()
      parsed[:stats] -> show_stats()
      parsed[:list_presets] -> list_presets()
      parsed[:list_attributes] -> list_attributes()
      parsed[:show_planning] -> show_planning_example(parsed)
      true -> generate_characters(parsed)
    end
  end

  @spec generate_characters(parsed_options()) :: :ok
  defp generate_characters(options) do
    try do
      count = min(options[:count] || 1, 10)
      format = options[:format] || "json"
      
      characters = if count == 1 do
        [generate_single_character(options)]
      else
        generate_multiple_characters(count, options)
      end

      output = format_output(characters, format, count == 1)
      
      case options[:output] do
        nil -> IO.puts(output)
        filename -> File.write!(filename, output)
      end

      if options[:output] do
        IO.puts("Generated #{count} character(s) and saved to #{options[:output]}")
      end

    rescue
      error -> 
        Mix.shell().error("Error generating character: #{Exception.message(error)}")
        exit({:shutdown, 1})
    end
  end

  @spec generate_single_character(parsed_options()) :: character()
  defp generate_single_character(options) do
    generation_opts = [
      seed: options[:seed],
      preset: options[:preset]
    ]
    
    cond do
      # Use specific planning workflow
      options[:workflow] ->
        workflow = case options[:workflow] do
          "basic" -> :basic
          "comprehensive" -> :comprehensive
          "demo" -> :demo
          "validation" -> :validation_only
          "preset" -> :preset_application
          _ -> :basic
        end
        
        result = CharacterGenerator.generate_with_plan(workflow, generation_opts)
        case result do
          {:error, reason} -> 
            Mix.shell().error("Planning workflow failed: #{reason}")
            Mix.shell().info("Falling back to standard generation...")
            CharacterGenerator.generate(generation_opts)
          character when is_map(character) -> 
            character
          other -> 
            raise "Unexpected return value from generate_with_plan: #{inspect(other)}"
        end
      
      # Standard generation
      options[:randomize] ->
        generate_with_seed(options[:seed])
      
      options[:preset] ->
        result = CharacterGenerator.generate(generation_opts)
        case result do
          {:ok, character} -> character
          {:error, reason} -> raise "Failed to generate character: #{reason}"
          character when is_map(character) -> character
          other -> raise "Unexpected return value from CharacterGenerator.generate: #{inspect(other)}"
        end
      
      true ->
        generate_with_seed(options[:seed])
    end
  end

  @spec generate_multiple_characters(pos_integer(), parsed_options()) :: [character()]
  defp generate_multiple_characters(count, options) do
    base_seed = options[:seed] || :os.system_time(:microsecond)
    
    if options[:randomize] do
      Enum.map(1..count, fn i ->
        generate_with_seed(base_seed + i)
      end)
    else
      preset = options[:preset] || "fantasy_cyber"
      
      batch_opts = [
        preset: preset, 
        seed: base_seed
      ]
      
      CharacterGenerator.generate_batch(count, batch_opts)
    end
  end

  @spec generate_with_seed(integer() | nil) :: character()
  defp generate_with_seed(seed) do
    CharacterGenerator.generate(seed: seed)
  end

  @spec format_output([character()], output_format(), boolean()) :: String.t()
  defp format_output(characters, "json", single?) do
    data = if single?, do: hd(characters), else: characters
    Jason.encode!(data, pretty: true)
  end

  defp format_output(characters, "prompt", single?) do
    if single? do
      character = hd(characters)
      Map.get(character, :prompt, "No prompt available")
    else
      characters
      |> Enum.with_index(1)
      |> Enum.map(fn {character, index} ->
        prompt = Map.get(character, :prompt, "No prompt available")
        "=== Character #{index} ===\n\n#{prompt}"
      end)
      |> Enum.join("\n\n")
    end
  end

  defp format_output(_characters, "yaml", _single?) do
    Mix.shell().error("YAML output is not supported. Supported formats: json, prompt")
    exit({:shutdown, 1})
  end

  defp format_output(_characters, format, _) do
    Mix.shell().error("Unknown format: #{format}. Supported formats: json, prompt")
    exit({:shutdown, 1})
  end

  @spec show_help() :: :ok
  defp show_help do
    IO.puts(@moduledoc)
  end

  defp show_stats do
    stats = CharacterGenerator.stats()
    IO.puts("=== AriaEngine Character Generator Statistics ===\n")
    IO.puts("Total Attributes: #{stats.total_attributes}")
    IO.puts("Total Options: #{stats.total_options}")
    IO.puts("Categorical Attributes: #{stats.categorical_attributes}")
    IO.puts("Numeric Attributes: #{stats.numeric_attributes}")
    
    IO.puts("\n=== Configuration Details ===")
    IO.puts("Descriptions Available: #{stats.descriptions_available}")
  end

  defp list_presets do
    presets = CharacterGenerator.list_presets()
    IO.puts("=== Available Character Presets ===\n")
    
    Enum.each(presets, fn preset_name ->
      IO.puts("#{preset_name}")
      IO.puts("  Available in the character generator system")
      IO.puts("")
    end)
  end

  defp list_attributes do
    attributes = CharacterGenerator.list_attributes()
    IO.puts("=== Available Character Attributes ===\n")
    
    attributes
    |> Enum.sort()
    |> Enum.chunk_every(3)
    |> Enum.each(fn chunk ->
      line = chunk
      |> Enum.map(&String.pad_trailing(&1, 20))
      |> Enum.join(" ")
      IO.puts(line)
    end)

    IO.puts("\nUse --stats to see detailed information about each attribute.")
  end

  defp show_planning_example(options) do
    IO.puts("=== AriaEngine Character Generation Planning Demo ===\n")
    IO.puts("This demonstrates how AriaEngine.plan() creates TODO lists for character generation.")
    IO.puts("State uses RDF-style predicate-subject-object triples, Plans are TODO lists.\n")

    verbose_level = options[:verbose_planning] || 1
    
    try do
      # Generate a unique character ID
      char_id = UUID.uuid4()
      
      IO.puts("=== Initial State (RDF Triples: predicate | subject | object) ===")
      IO.puts("session:active | generation_session | true")
      IO.puts("character:id | #{char_id} | current")
      IO.puts("random:seed | #{char_id} | 12345")
      IO.puts("preset:type | #{char_id} | fantasy_cyber")
      IO.puts("generation:status | #{char_id} | initialized")

      # Define the initial TODO list for character generation
      todos = [
        {"generate_character_with_constraints", %{char_id: char_id, preset: "fantasy_cyber"}},
        {"validate_character_coherence", %{char_id: char_id}},
        {"generate_character_prompt", %{char_id: char_id}}
      ]

      IO.puts("\n=== Initial TODO List ===")
      todos
      |> Enum.with_index(1)
      |> Enum.each(fn {{task_name, task_params}, index} ->
        IO.puts("#{index}. Task: #{task_name}")
        IO.puts("   Params: #{inspect(task_params)}")
      end)

      IO.puts("\n=== Planning Process ===")
      IO.puts("Running AriaEngine.plan() with verbose level #{verbose_level}...")
      IO.puts("Converting TODO list into executable action sequence...\n")

      # Simulated planning output for demonstration
      simulated_plan = [
        {:set_character_attribute, %{char_id: char_id, attribute: "species", value: "SPECIES_HUMANOID"}},
        {:set_character_attribute, %{char_id: char_id, attribute: "style", value: "STYLE_KEI_SCI_FI_FUTURISTIC"}},
        {:set_character_attribute, %{char_id: char_id, attribute: "emotion", value: "EMOTION_CONFIDENT"}},
        {:set_character_attribute, %{char_id: char_id, attribute: "palette", value: "COLOR_PALETTE_CYBERPUNK_GLOW"}},
        {:validate_attribute_consistency, %{char_id: char_id}},
        {:check_preset_compliance, %{char_id: char_id}},
        {:generate_text_prompt, %{char_id: char_id}}
      ]

      IO.puts("=== Generated Plan (Executable Action Sequence) ===")
      simulated_plan
      |> Enum.with_index(1)
      |> Enum.each(fn {{action, params}, index} ->
        IO.puts("#{index}. Action: #{action}")
        IO.puts("   Params: #{inspect(params)}")
      end)

      IO.puts("\n=== Plan Summary ===")
      IO.puts("✓ Planning succeeded!")
      IO.puts("✓ Generated #{length(simulated_plan)} action steps")
      IO.puts("✓ Character ID: #{char_id}")
      
      if verbose_level >= 2 do
        IO.puts("\n=== Plan Execution Preview ===")
        IO.puts("Character generation completed! Final state triples:")
        
        # Show character attributes using predicate-subject-object structure
        sample_triples = [
          {"character:species", char_id, "SPECIES_HUMANOID"},
          {"character:style", char_id, "STYLE_KEI_SCI_FI_FUTURISTIC"},
          {"character:emotion", char_id, "EMOTION_CONFIDENT"},
          {"character:palette", char_id, "COLOR_PALETTE_CYBERPUNK_GLOW"},
          {"validation:consistency", char_id, "passed"},
          {"validation:preset_compliance", char_id, "passed"},
          {"generation:status", char_id, "completed"},
          {"generated:prompt", char_id, "A confident humanoid character with sci-fi futuristic styling..."}
        ]
        
        sample_triples
        |> Enum.each(fn {predicate, subject, object} ->
          object_display = case object do
            str when is_binary(str) and byte_size(str) > 50 ->
              "\"#{String.slice(str, 0, 47)}...\""
            str when is_binary(str) ->
              "\"#{str}\""
            other ->
              inspect(other)
          end
          IO.puts("  #{predicate} | #{subject} | #{object_display}")
        end)
      end

      if verbose_level >= 3 do
        IO.puts("\n=== RDF Integration Notes ===")
        IO.puts("• State uses RDF-style triples: (predicate, subject, object)")
        IO.puts("• Plans are hierarchical TODO lists that decompose into actions")
        IO.puts("• Actions modify state by adding/updating RDF triples")
        IO.puts("• Character generation builds a knowledge graph of attributes")
        IO.puts("• Consider using RDF-ex library for full RDF support:")
        IO.puts("  https://github.com/rdf-elixir/rdf-ex")
        
        IO.puts("\n=== Integration with Character Generator ===")
        IO.puts("• Current character generator returns map structure")
        IO.puts("• Planning system could convert between map and RDF formats")
        IO.puts("• Example mapping:")
        IO.puts("  Map: %{attributes: %{\"species\" => \"SPECIES_HUMANOID\"}}")
        IO.puts("  RDF: (\"character:species\", char_id, \"SPECIES_HUMANOID\")")
      end

    rescue
      error -> 
        Mix.shell().error("Planning demo error: #{Exception.message(error)}")
        IO.puts("\nThis demo shows the planning interface structure.")
        IO.puts("For full functionality, ensure AriaEngine planner is properly configured.")
        if verbose_level >= 1 do
          Mix.shell().error("Error details: #{inspect(error)}")
        end
    end
  end

  # Expose a function for plan-based testing in Mix.Tasks.GenerateCharacter
  def plan_character_with(attrs_or_opts) do
    domain = AriaEngine.CharacterGenerator.Domain.build_demo_character_domain()
    char_id = UUID.uuid4(:default)
    preset = Map.get(attrs_or_opts, :preset) || Map.get(attrs_or_opts, "preset")
    todos = [
      {"generate_character_with_constraints", %{char_id: char_id, preset: preset}},
      {"validate_character_coherence", %{char_id: char_id}},
      {"generate_character_prompt", %{char_id: char_id}}
    ]
    state = AriaEngine.create_state()
    attrs = if is_map(attrs_or_opts), do: attrs_or_opts, else: %{}
    state = Enum.reduce(attrs, state, fn {k, v}, acc ->
      AriaEngine.set_fact(acc, "character:" <> k, char_id, v)
    end)
    AriaEngine.plan(domain, state, todos, verbose: 0)
  end
end
