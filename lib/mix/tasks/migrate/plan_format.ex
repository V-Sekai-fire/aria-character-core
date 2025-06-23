# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.PlanFormat do
  @moduledoc """
  Migrate test files from list-based plan format to solution tree format.

  This task uses AST transformations to systematically update test assertions
  that expect plans to be lists to work with the new solution tree format.

  ## Usage

      mix migrate.plan_format

  ## Transformations Applied

  1. `assert is_list(plan)` → `assert %{nodes: _, root_id: _} = plan`
  2. `assert length(plan) > 0` → `assert map_size(plan.nodes) > 0`
  3. `assert length(plan) == N` → `assert map_size(plan.nodes) == N`

  ## Files Processed

  - All test files in `test/` directory
  - Only files containing plan-related assertions are modified
  """

  use Mix.Task
  alias Mix.Tasks.Migrate.{Base, AstTransformer}

  @shortdoc "Migrate test files from list-based plan format to solution tree format"

  @impl Mix.Task
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [dry_run: :boolean, verbose: :boolean])

    dry_run = Keyword.get(opts, :dry_run, false)
    verbose = Keyword.get(opts, :verbose, false)

    if dry_run do
      Mix.shell().info("Running in dry-run mode - no files will be modified")
    end

    # Find all test files
    test_files = find_test_files()

    if verbose do
      Mix.shell().info("Found #{length(test_files)} test files to check")
    end

    # Process each file
    results = Enum.map(test_files, fn file_path ->
      process_file(file_path, dry_run, verbose)
    end)

    # Report results
    report_results(results, dry_run)
  end

  defp find_test_files do
    Path.wildcard("test/**/*_test.exs")
  end

  defp process_file(file_path, dry_run, verbose) do
    case File.read(file_path) do
      {:ok, content} ->
        if AstTransformer.needs_plan_format_transformation?(content) do
          if verbose do
            Mix.shell().info("Processing: #{file_path}")
          end

          case AstTransformer.transform_code(content, AstTransformer.plan_format_migration_rules()) do
            {:changed, new_content} ->
              if not dry_run do
                File.write!(file_path, new_content)
              end

              if verbose do
                Mix.shell().info("  ✓ Transformed")
              end

              {:changed, file_path}

            :unchanged ->
              if verbose do
                Mix.shell().info("  - No changes needed")
              end

              {:unchanged, file_path}

            {:error, reason} ->
              Mix.shell().error("  ✗ Error transforming #{file_path}: #{reason}")
              {:error, file_path, reason}
          end
        else
          if verbose do
            Mix.shell().info("Skipping: #{file_path} (no plan assertions found)")
          end

          {:skipped, file_path}
        end

      {:error, reason} ->
        Mix.shell().error("Error reading #{file_path}: #{reason}")
        {:error, file_path, reason}
    end
  end

  defp report_results(results, dry_run) do
    changed = Enum.count(results, fn
      {:changed, _} -> true
      _ -> false
    end)
    unchanged = Enum.count(results, fn
      {:unchanged, _} -> true
      _ -> false
    end)
    skipped = Enum.count(results, fn
      {:skipped, _} -> true
      _ -> false
    end)
    errors = Enum.count(results, fn
      {:error, _, _} -> true
      _ -> false
    end)

    Mix.shell().info("\nMigration Summary:")
    Mix.shell().info("  Changed: #{changed}")
    Mix.shell().info("  Unchanged: #{unchanged}")
    Mix.shell().info("  Skipped: #{skipped}")

    if errors > 0 do
      Mix.shell().info("  Errors: #{errors}")
    end

    if dry_run and changed > 0 do
      Mix.shell().info("\nRun without --dry-run to apply changes")
    end

    if changed > 0 and not dry_run do
      Mix.shell().info("\n✓ Plan format migration completed successfully")
      Mix.shell().info("Run tests to verify the changes work correctly")
    end
  end
end
