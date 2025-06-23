# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.DomainFromModule do
  @moduledoc """
  Migrate Domain.from_module calls to direct build() calls.

  This task uses AST transformations to replace deprecated Domain.from_module/1
  calls with direct calls to the domain module's build/0 function, following
  Elixir's idiomatic approach of explicit function calls over reflection.

  ## Usage

      mix migrate.domain_from_module [files...]

  If no files are specified, all test files will be processed.

  ## Transformations Applied

  1. `AriaEngine.Domain.from_module(AriaEngine.SoftwareDevelopment.Domain)`
     → `AriaEngine.SoftwareDevelopment.Domain.build()`
  2. `AriaEngine.Domain.from_module(SomeDomain)`
     → `SomeDomain.build()`

  ## Files Processed

  - Specified files, or all test files in `test/` directory if none specified
  - Only files containing Domain.from_module calls are modified
  """

  use Mix.Task
  alias Mix.Tasks.Migrate.AstTransformer

  @shortdoc "Migrate Domain.from_module calls to direct build() calls"

  @impl Mix.Task
  def run(args) do
    {opts, files} = OptionParser.parse!(args, strict: [dry_run: :boolean, verbose: :boolean])

    dry_run = Keyword.get(opts, :dry_run, false)
    verbose = Keyword.get(opts, :verbose, false)

    if dry_run do
      Mix.shell().info("Running in dry-run mode - no files will be modified")
    end

    # Determine which files to process
    target_files = if Enum.empty?(files) do
      find_test_files()
    else
      files
    end

    if verbose do
      Mix.shell().info("Found #{length(target_files)} files to check")
    end

    # Process each file
    results = Enum.map(target_files, fn file_path ->
      process_file(file_path, dry_run, verbose)
    end)

    # Report results
    report_results(results, dry_run)
  end

  defp find_test_files do
    Path.wildcard("test/**/*.exs")
  end

  defp process_file(file_path, dry_run, verbose) do
    case File.read(file_path) do
      {:ok, content} ->
        if needs_domain_from_module_transformation?(content) do
          if verbose do
            Mix.shell().info("Processing: #{file_path}")
          end

          case AstTransformer.transform_code(content, domain_from_module_rules()) do
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
            Mix.shell().info("Skipping: #{file_path} (no Domain.from_module calls found)")
          end

          {:skipped, file_path}
        end

      {:error, reason} ->
        Mix.shell().error("Error reading #{file_path}: #{reason}")
        {:error, file_path, reason}
    end
  end

  defp needs_domain_from_module_transformation?(source_code) do
    String.contains?(source_code, "Domain.from_module(")
  end

  defp domain_from_module_rules do
    [domain_from_module_rule()]
  end

  defp domain_from_module_rule do
    fn ast_node ->
      case ast_node do
        # Match: AriaEngine.Domain.from_module(AriaEngine.SoftwareDevelopment.Domain)
        {{:., meta, [{:__aliases__, _alias_meta, [:AriaEngine, :Domain]}, :from_module]}, call_meta,
         [{:__aliases__, domain_alias_meta, domain_module_path}]} when is_list(domain_module_path) ->
          # Replace with: DomainModule.build()
          {{:., meta, [{:__aliases__, domain_alias_meta, domain_module_path}, :build]}, call_meta, []}

        # Match: Domain.from_module(SomeDomain) when Domain is aliased
        {{:., meta, [{:__aliases__, _alias_meta, [:Domain]}, :from_module]}, call_meta,
         [{:__aliases__, domain_alias_meta, domain_module_path}]} when is_list(domain_module_path) ->
          # Replace with: DomainModule.build()
          {{:., meta, [{:__aliases__, domain_alias_meta, domain_module_path}, :build]}, call_meta, []}

        _ ->
          ast_node
      end
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
      Mix.shell().info("\n✓ Domain from_module migration completed successfully")
      Mix.shell().info("Run tests to verify the changes work correctly")
    end
  end
end
