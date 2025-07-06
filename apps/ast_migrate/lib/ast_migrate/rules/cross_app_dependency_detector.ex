# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AstMigrate.Rules.CrossAppDependencyDetector do
  @moduledoc """
  AST-based detection of cross-app dependency violations in umbrella projects.

  This rule systematically detects violations of the external API boundary pattern
  where apps directly import internal modules from other apps instead of using
  external APIs.

  ## Violation Types Detected

  - **Legacy namespace violations**: `AriaEngine.*`, `AriaCore.*` patterns
  - **Internal module imports**: Direct `alias App.Internal.Module` across apps
  - **Timeline violations**: `AriaTimeline.TimelineCore.*` usage
  - **Engine core violations**: `AriaEngineCore.*` direct usage

  ## Usage

      # Detect all violations across the codebase
      AstMigrate.apply_rule(:cross_app_dependency_detector, dry_run: true)

      # Generate violation report
      AstMigrate.apply_rule(:cross_app_dependency_detector,
        files: ["apps/**/*.ex"],
        dry_run: true)
  """

  @behaviour AstMigrate.Rules.Behaviour

  require Logger

  @impl true
  def description do
    "Detects cross-app dependency violations where apps import internal modules from other apps"
  end

  @impl true
  def file_patterns do
    [
      "apps/*/lib/**/*.ex",
      "apps/*/test/**/*.ex",
      "apps/*/test/**/*.exs",
      "apps/*/**/*.exs"
    ]
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
          violations = detect_violations(ast, file_path)
          report = generate_violation_report(violations, file_path)

          Logger.info("Cross-app dependency analysis completed",
            file: file_path,
            violations_found: length(violations)
          )

          # Return original content with violation report in comments
          enhanced_content = add_violation_report_to_content(content, report)
          {:ok, enhanced_content}

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

  defp detect_violations(ast, file_path) do
    app_name = extract_app_name(file_path)

    ast
    |> extract_aliases()
    |> Enum.flat_map(fn alias_node ->
      analyze_alias_violation(alias_node, app_name, file_path)
    end)
  end

  defp extract_app_name(file_path) do
    case Regex.run(~r/apps\/([^\/]+)\//, file_path) do
      [_, app_name] -> app_name
      _ -> "unknown"
    end
  end

  defp extract_aliases(ast) do
    {_ast, aliases} = Macro.prewalk(ast, [], fn
      {:alias, _meta, [alias_module]} = node, acc ->
        {node, [alias_module | acc]}

      {:alias, _meta, [alias_module, [as: _as_name]]} = node, acc ->
        {node, [alias_module | acc]}

      node, acc ->
        {node, acc}
    end)

    Enum.reverse(aliases)
  end

  defp analyze_alias_violation(alias_module, current_app, file_path) do
    alias_string = module_to_string(alias_module)

    cond do
      # Legacy namespace violations
      String.starts_with?(alias_string, "AriaEngine.") ->
        [create_violation(:legacy_namespace, alias_string, current_app, file_path, "AriaEngine namespace should use proper app APIs")]

      String.starts_with?(alias_string, "AriaCore.") and current_app != "aria_core" ->
        [create_violation(:legacy_namespace, alias_string, current_app, file_path, "AriaCore namespace should use AriaCore external API")]

      # Timeline violations
      String.starts_with?(alias_string, "AriaTimeline.TimelineCore") and current_app != "aria_timeline" ->
        [create_violation(:internal_module_import, alias_string, current_app, file_path, "Should use AriaTimeline external API")]

      # Engine core violations
      String.starts_with?(alias_string, "AriaEngineCore.") and current_app != "aria_engine_core" ->
        [create_violation(:internal_module_import, alias_string, current_app, file_path, "Should use AriaEngineCore external API")]

      # General internal module violations
      is_cross_app_internal_import?(alias_string, current_app) ->
        [create_violation(:internal_module_import, alias_string, current_app, file_path, "Cross-app internal module import")]

      true ->
        []
    end
  end

  defp module_to_string(module_ast) do
    case module_ast do
      {:__aliases__, _, parts} ->
        Enum.join(parts, ".")

      atom when is_atom(atom) ->
        Atom.to_string(atom)

      _ ->
        inspect(module_ast)
    end
  end

  defp is_cross_app_internal_import?(alias_string, current_app) do
    # Check if this is importing an internal module from another app
    app_prefixes = [
      "AriaAuth", "AriaCore", "AriaEngineCore", "AriaGltf",
      "AriaHybridPlanner", "AriaMembranePipeline", "AriaMinizincExecutor",
      "AriaMinizincGoal", "AriaMinizincMultiply", "AriaMinizincStn",
      "AriaSecurity", "AriaSerial", "AriaState", "AriaStorage",
      "AriaTimeline", "AriaTimelineIntervals", "AriaTown", "AstMigrate"
    ]

    Enum.any?(app_prefixes, fn prefix ->
      String.starts_with?(alias_string, prefix <> ".") and
      not is_external_api_import?(alias_string) and
      not is_same_app_import?(alias_string, current_app)
    end)
  end

  defp is_external_api_import?(alias_string) do
    # External API imports are just the app name (e.g., "AriaCore", "AriaTimeline")
    app_names = [
      "AriaAuth", "AriaCore", "AriaEngineCore", "AriaGltf",
      "AriaHybridPlanner", "AriaMembranePipeline", "AriaMinizincExecutor",
      "AriaMinizincGoal", "AriaMinizincMultiply", "AriaMinizincStn",
      "AriaSecurity", "AriaSerial", "AriaState", "AriaStorage",
      "AriaTimeline", "AriaTimelineIntervals", "AriaTown", "AstMigrate"
    ]

    Enum.member?(app_names, alias_string)
  end

  defp is_same_app_import?(alias_string, current_app) do
    app_name_mapping = %{
      "aria_auth" => "AriaAuth",
      "aria_core" => "AriaCore",
      "aria_engine_core" => "AriaEngineCore",
      "aria_gltf" => "AriaGltf",
      "aria_hybrid_planner" => "AriaHybridPlanner",
      "aria_membrane_pipeline" => "AriaMembranePipeline",
      "aria_minizinc_executor" => "AriaMinizincExecutor",
      "aria_minizinc_goal" => "AriaMinizincGoal",
      "aria_minizinc_multiply" => "AriaMinizincMultiply",
      "aria_minizinc_stn" => "AriaMinizincStn",
      "aria_security" => "AriaSecurity",
      "aria_serial" => "AriaSerial",
      "aria_state" => "AriaState",
      "aria_storage" => "AriaStorage",
      "aria_timeline" => "AriaTimeline",
      "aria_timeline_intervals" => "AriaTimelineIntervals",
      "aria_town" => "AriaTown",
      "ast_migrate" => "AstMigrate"
    }

    expected_prefix = Map.get(app_name_mapping, current_app, "")
    String.starts_with?(alias_string, expected_prefix <> ".")
  end

  defp create_violation(type, alias_string, current_app, file_path, description) do
    %{
      type: type,
      alias: alias_string,
      current_app: current_app,
      file: file_path,
      description: description,
      suggested_fix: suggest_fix(type, alias_string)
    }
  end

  defp suggest_fix(:legacy_namespace, alias_string) do
    cond do
      String.starts_with?(alias_string, "AriaEngine.Timeline") ->
        "Use AriaTimeline external API"

      String.starts_with?(alias_string, "AriaEngine.") ->
        "Use AriaEngineCore external API"

      String.starts_with?(alias_string, "AriaCore.") ->
        "Use AriaCore external API"

      true ->
        "Use appropriate external API"
    end
  end

  defp suggest_fix(:internal_module_import, alias_string) do
    cond do
      String.starts_with?(alias_string, "AriaTimeline.TimelineCore") ->
        "Replace with AriaTimeline external API calls"

      String.starts_with?(alias_string, "AriaEngineCore.") ->
        "Replace with AriaEngineCore external API calls"

      true ->
        "Replace with external API calls"
    end
  end

  defp generate_violation_report(violations, file_path) do
    if Enum.empty?(violations) do
      "# Cross-app dependency analysis: No violations found"
    else
      violation_summary =
        violations
        |> Enum.group_by(& &1.type)
        |> Enum.map(fn {type, type_violations} ->
          "# #{type}: #{length(type_violations)} violations"
        end)
        |> Enum.join("\n")

      violation_details =
        violations
        |> Enum.map(fn violation ->
          "# - #{violation.alias}: #{violation.description} (#{violation.suggested_fix})"
        end)
        |> Enum.join("\n")

      """
      # Cross-app dependency violations found in #{file_path}
      #{violation_summary}

      # Details:
      #{violation_details}
      """
    end
  end

  defp add_violation_report_to_content(content, report) do
    # Add report as comments at the top of the file
    case String.split(content, "\n", parts: 2) do
      [first_line, rest] ->
        first_line <> "\n" <> report <> "\n" <> rest

      [single_line] ->
        single_line <> "\n" <> report
    end
  end
end
