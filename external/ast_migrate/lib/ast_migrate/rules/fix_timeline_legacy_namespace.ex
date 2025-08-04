# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AstMigrate.Rules.FixTimelineLegacyNamespace do
  @moduledoc """
  AST-based transformation to fix AriaEngine.Timeline.* → AriaTimeline API violations.

  This rule systematically transforms legacy AriaEngine.Timeline namespace usage
  to use the proper AriaTimeline external API.

  ## Transformations Applied

  - `alias AriaEngine.Timeline.*` → `alias AriaTimeline`
  - `AriaEngine.Timeline.function()` → `AriaTimeline.function()`
  - Updates module references and function calls

  ## Usage

      # Apply timeline legacy namespace fixes
      AstMigrate.apply_rule(:fix_timeline_legacy_namespace)

      # Preview changes without applying
      AstMigrate.apply_rule(:fix_timeline_legacy_namespace, dry_run: true)
  """

  @behaviour AstMigrate.Rules.Behaviour

  require Logger

  @impl true
  def description do
    "Transforms AriaEngine.Timeline.* legacy namespace usage to AriaTimeline external API"
  end

  @impl true
  def file_patterns do
    ["apps/aria_*/lib/**/*.ex"]
  end

  @impl true
  def preconditions do
    [
      &file_exists?/1,
      &is_elixir_file?/1
    ]
  end

  @impl true
  def postconditions do
    [
      &file_exists?/1,
      &is_valid_elixir?/1
    ]
  end

  @impl true
  def validate_preconditions(files) do
    invalid_files =
      files
      |> Enum.reject(fn file ->
        Enum.all?(preconditions(), fn condition -> condition.(file) end)
      end)

    case invalid_files do
      [] -> :ok
      files -> {:error, "Invalid files: #{inspect(files)}"}
    end
  end

  @impl true
  def transform_file(file_path) do
    try do
      content = File.read!(file_path)

      case Code.string_to_quoted(content) do
        {:ok, ast} ->
          {transformed_ast, changes_made} = transform_timeline_legacy_namespace(ast)

          if changes_made do
            transformed_content = Macro.to_string(transformed_ast)
            # Clean up formatting
            cleaned_content = format_elixir_code(transformed_content)

            Logger.info("Timeline legacy namespace transformation applied",
              file: file_path,
              changes_made: true
            )

            {:ok, cleaned_content}
          else
            Logger.debug("No timeline legacy namespace violations found",
              file: file_path
            )

            {:ok, content}
          end

        {:error, reason} ->
          {:error, "Failed to parse #{file_path}: #{inspect(reason)}"}
      end
    rescue
      error ->
        {:error, "Error processing #{file_path}: #{inspect(error)}"}
    end
  end

  # Private functions

  defp file_exists?(file_path) do
    File.exists?(file_path)
  end

  defp is_elixir_file?(file_path) do
    String.ends_with?(file_path, ".ex") or String.ends_with?(file_path, ".exs")
  end

  defp is_valid_elixir?(file_path) do
    try do
      content = File.read!(file_path)
      case Code.string_to_quoted(content) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    rescue
      _ -> false
    end
  end

  defp transform_timeline_legacy_namespace(ast) do
    Macro.prewalk(ast, false, fn node, changes_made ->
      case node do
        # Transform defmodule declarations within aria_timeline app to proper internal names
        {:defmodule, meta, [{:__aliases__, _, [:AriaEngine, :Timeline | rest_modules]}, module_body]} ->
          # AriaEngine.Timeline.Module → Timeline.Module (internal modules)
          new_module_name = {:__aliases__, [alias: false], [:Timeline | rest_modules]}
          new_defmodule = {:defmodule, meta, [new_module_name, module_body]}
          {new_defmodule, true}

        # Transform alias statements for cross-app usage
        {:alias, meta, [{{:., _, [{:__aliases__, _, [:AriaEngine]}, :Timeline]}, _, _timeline_modules}]} ->
          # AriaEngine.Timeline.* → AriaTimeline (for cross-app usage)
          new_alias = {:alias, meta, [{:__aliases__, [alias: false], [:AriaTimeline]}]}
          {new_alias, true}

        {:alias, meta, [{{:., _, [{:__aliases__, _, [:AriaEngine]}, :Timeline]}, _, _timeline_modules}, opts]} ->
          # AriaEngine.Timeline.* with options → AriaTimeline
          new_alias = {:alias, meta, [{:__aliases__, [alias: false], [:AriaTimeline]}, opts]}
          {new_alias, true}

        # Transform direct module references for cross-app calls
        {{:., _, [{:__aliases__, _, [:AriaEngine, :Timeline | _rest_modules]}, function_name]}, _, args} ->
          # AriaEngine.Timeline.Module.function() → AriaTimeline.function()
          new_call = {{:., [], [{:__aliases__, [alias: false], [:AriaTimeline]}, function_name]}, [], args}
          {new_call, true}

        # Transform simple AriaEngine.Timeline references to AriaTimeline for cross-app
        {:__aliases__, meta, [:AriaEngine, :Timeline | rest_modules]} when rest_modules != [] ->
          # AriaEngine.Timeline.Module → Timeline.Module (internal references)
          new_alias = {:__aliases__, meta, [:Timeline | rest_modules]}
          {new_alias, true}

        _ ->
          {node, changes_made}
      end
    end)
  end

  defp format_elixir_code(code_string) do
    # Basic formatting cleanup
    code_string
    |> String.replace(~r/\n\s*\n\s*\n/, "\n\n")  # Remove excessive blank lines
    |> String.replace(~r/,\s*\n\s*}/, "\n}")      # Fix trailing commas in maps/structs
    |> String.trim()
  end
end
