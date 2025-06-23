defmodule Mix.Tasks.Ast.Simple do
  @moduledoc "Simple AST transformation tool for immediate relief.\n\nThis task provides the Phase 0 implementation of the Git-Native AST Migration Tool,\nfocusing on StateV2 → State migration with Git integration.\n\n## Usage\n\n    # Apply transformation and commit\n    mix ast.simple --rule state_v2_to_state --commit \"Convert StateV2 to State\"\n\n    # Dry run to preview changes\n    mix ast.simple --rule state_v2_to_state --dry-run\n\n    # Apply to specific files\n    mix ast.simple --rule state_v2_to_state --files \"lib/aria_engine/*.ex\"\n\n## Options\n\n- `--rule` - Transformation rule to apply (required)\n- `--commit` - Commit message for automatic Git commit\n- `--dry-run` - Preview changes without applying them\n- `--files` - Comma-separated list of file patterns (default: lib/**/*.ex,test/**/*.exs)\n\n## Examples\n\n    # Convert StateV2 to State and commit changes\n    mix ast.simple --rule state_v2_to_state --commit \"Convert StateV2 to State in engine\"\n\n    # Preview what would be changed\n    mix ast.simple --rule state_v2_to_state --dry-run\n\n    # Apply only to specific files\n    mix ast.simple --rule state_v2_to_state --files \"lib/aria_engine/actions.ex\"\n"
  use Mix.Task
  @shortdoc "Apply simple AST transformations with Git integration"
  @impl Mix.Task
  def run(args) do
    {opts, _args, _invalid} =
      OptionParser.parse(args,
        strict: [rule: :string, commit: :string, dry_run: :boolean, files: :string],
        aliases: [r: :rule, c: :commit, d: :dry_run, f: :files]
      )

    case validate_options(opts) do
      {:ok, validated_opts} ->
        execute_transformation(validated_opts)

      {:error, message} ->
        Mix.shell().error("Error: #{message}")
        System.halt(1)
    end
  end

  defp validate_options(opts) do
    with {:ok, rule} <- get_required_option(opts, :rule, "Rule is required (--rule)"),
         {:ok, rule_atom} <- validate_rule(rule) do
      validated_opts = %{
        rule: rule_atom,
        commit: Keyword.get(opts, :commit),
        dry_run: Keyword.get(opts, :dry_run, false),
        files: parse_file_patterns(Keyword.get(opts, :files))
      }

      {:ok, validated_opts}
    else
      error -> error
    end
  end

  defp get_required_option(opts, key, error_message) do
    case Keyword.get(opts, key) do
      nil -> {:error, error_message}
      value -> {:ok, value}
    end
  end

  defp validate_rule(rule_string) do
    rule_atom = String.to_atom(rule_string)

    if rule_atom in AstMigrate.list_rules() do
      {:ok, rule_atom}
    else
      available_rules = AstMigrate.list_rules() |> Enum.map(&to_string/1) |> Enum.join(", ")
      {:error, "Unknown rule '#{rule_string}'. Available rules: #{available_rules}"}
    end
  end

  defp parse_file_patterns(nil) do
    nil
  end

  defp parse_file_patterns(files_string) do
    files_string |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  defp execute_transformation(opts) do
    Mix.shell().info("🔧 AST Migration Tool - Phase 0")
    Mix.shell().info("Rule: #{opts.rule}")

    if opts.dry_run do
      Mix.shell().info("Mode: Dry run (preview only)")
    else
      Mix.shell().info("Mode: Apply transformations")
    end

    apply_opts = []

    apply_opts =
      if opts.commit do
        Keyword.put(apply_opts, :commit, opts.commit)
      else
        apply_opts
      end

    apply_opts =
      if opts.dry_run do
        Keyword.put(apply_opts, :dry_run, true)
      else
        apply_opts
      end

    apply_opts =
      if opts.files do
        Keyword.put(apply_opts, :files, opts.files)
      else
        apply_opts
      end

    case AstMigrate.apply_rule(opts.rule, apply_opts) do
      {:ok, result} ->
        display_results(result, opts)

      {:error, reason} ->
        Mix.shell().error("Transformation failed: #{reason}")
        System.halt(1)
    end
  end

  defp display_results(result, opts) do
    Mix.shell().info("")
    Mix.shell().info("✅ Transformation completed successfully!")
    Mix.shell().info("Files processed: #{result.files_processed}")
    Mix.shell().info("Files changed: #{result.files_changed}")

    if opts.dry_run do
      Mix.shell().info("(Dry run - no files were actually modified)")
    else
      if result.commit_hash do
        Mix.shell().info("Committed with hash: #{result.commit_hash}")
      end
    end

    if result.files_changed == 0 do
      Mix.shell().info("No files needed transformation.")
    end
  end
end