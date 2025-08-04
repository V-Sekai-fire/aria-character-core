# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.DetectViolations do
  @moduledoc """
  Debug tool to detect cross-app dependency violations with verbose output.
  """

  use Mix.Task
  require Logger

  @impl Mix.Task
  def run(args) do
    {_opts, _, _} = OptionParser.parse(args, switches: [verbose: :boolean])

    Logger.debug("=== Cross-App Dependency Violation Detection ===")

    file_patterns = [
      "apps/*/lib/**/*.ex",
      "apps/*/test/**/*.ex",
      "apps/*/test/**/*.exs",
      "apps/*/**/*.exs"
    ]

    files =
      file_patterns
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.filter(&File.exists?/1)
      |> Enum.filter(&is_elixir_file?/1)

    Logger.debug("Scanning #{length(files)} files...")

    total_violations =
      files
      |> Enum.map(fn file ->
        violations = detect_violations_in_file(file)
        if not Enum.empty?(violations) do
          Logger.debug("\n📁 #{file}")
          Enum.each(violations, fn violation ->
            Logger.debug("  ❌ #{violation.type}: #{violation.alias}")
            Logger.debug("     #{violation.description}")
            Logger.debug("     💡 #{violation.suggested_fix}")
          end)
        end
        length(violations)
      end)
      |> Enum.sum()

    Logger.debug("\n=== Summary ===")
    Logger.debug("Total violations found: #{total_violations}")
  end

  defp is_elixir_file?(file_path) do
    String.ends_with?(file_path, ".ex") or String.ends_with?(file_path, ".exs")
  end

  defp detect_violations_in_file(file_path) do
    try do
      content = File.read!(file_path)

      case Code.string_to_quoted(content) do
        {:ok, ast} ->
          app_name = extract_app_name(file_path)
          aliases = extract_aliases(ast)

          aliases
          |> Enum.flat_map(fn alias_node ->
            analyze_alias_violation(alias_node, app_name, file_path)
          end)

        {:error, _reason} ->
          []
      end
    rescue
      _ -> []
    end
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
end
