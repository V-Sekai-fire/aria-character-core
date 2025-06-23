# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.Pipeline do
  @moduledoc """
  Main Membrane pipeline for code migration transformations.

  This pipeline processes files through a series of transformation rules,
  providing streaming processing capabilities for large codebases.
  """

  use Membrane.Pipeline

  alias AriaEngine.Membrane.Migration.{
    RuleDetector,
    RuleRouter,
    ResultCollector,
    Registry
  }
  alias Membrane.File

  @type pipeline_options :: %{
    files: [String.t()],
    rules: [atom()] | :all,
    dry_run: boolean(),
    backup_dir: String.t(),
    verbose: boolean()
  }

  @impl true
  def handle_init(_ctx, options) do
    # Get applicable rules
    rules = case options.rules do
      :all -> Registry.list_all_rule_names()
      rule_list -> rule_list
    end

    # Build pipeline spec
    spec = [
      # Source: Read files using standard Membrane File.Source
      child(:file_source, %File.Source{
        location: get_first_file(options.files)
      }),

      # Detector: Identify applicable rules for each file
      child(:rule_detector, %RuleDetector{
        available_rules: rules
      }),

      # Router: Route files to appropriate rule bins
      child(:rule_router, %RuleRouter{
        rules: rules
      }),

      # Result Collector: Aggregate transformation results
      child(:result_collector, %ResultCollector{
        dry_run: options.dry_run
      }),

      # Sink: Write files using standard Membrane File.Sink
      child(:file_sink, %File.Sink{
        location: get_output_location(options)
      }),

      # Connect the main pipeline flow
      get_child(:file_source)
      |> via_out(:output)
      |> get_child(:rule_detector)
      |> via_out(:output)
      |> get_child(:rule_router)
      |> via_out(:output)
      |> get_child(:result_collector)
      |> via_out(:output)
      |> get_child(:file_sink)
    ]

    # Add rule bins dynamically
    rule_specs = create_rule_bin_specs(rules)

    {[spec: spec ++ rule_specs], %{rules: rules, options: options}}
  end

  @impl true
  def handle_child_notification({:file_processed, stats}, _child, _ctx, state) do
    # Handle file processing notifications for progress tracking
    if state.options.verbose do
      IO.puts("📁 Processed: #{stats.file_path} (#{stats.transformations} changes)")
    end

    {[], state}
  end

  @impl true
  def handle_child_notification({:pipeline_complete, summary}, _child, _ctx, state) do
    # Handle pipeline completion
    display_summary(summary, state.options)
    {[terminate: :normal], state}
  end

  @impl true
  def handle_child_notification(_notification, _child, _ctx, state) do
    {[], state}
  end

  # Private functions

  defp get_first_file(files) do
    case files do
      [first_file | _] when is_binary(first_file) -> first_file
      [] -> "."
      _ -> "."
    end
  end

  defp get_output_location(options) do
    if options.dry_run do
      "/dev/null"  # Discard output in dry run mode
    else
      # For now, use a temporary location - in a full implementation
      # this would be handled differently for multiple files
      Path.join(options.backup_dir, "migration_output.tmp")
    end
  end

  defp create_rule_bin_specs(rules) do
    Enum.map(rules, fn rule_name ->
      bin_module = Registry.get_rule_bin_module(rule_name)

      child(rule_name, bin_module)
    end)
  end

  defp display_summary(summary, options) do
    if options.dry_run do
      IO.puts("\n🔧 Membrane Migration Pipeline (DRY RUN)")
    else
      IO.puts("\n🔧 Membrane Migration Pipeline")
    end

    IO.puts("=" <> String.duplicate("=", 40))
    IO.puts("📊 Summary:")
    IO.puts("  Total files: #{summary.total_files}")
    IO.puts("  Changed: #{summary.changed_files}")
    IO.puts("  Unchanged: #{summary.unchanged_files}")
    IO.puts("  Skipped: #{summary.skipped_files}")
    IO.puts("  Total transformations: #{summary.total_transformations}")

    if options.dry_run do
      IO.puts("\n✅ Preview completed - no files were modified")
    else
      IO.puts("\n✅ Migration completed successfully!")
      IO.puts("💡 Backup files are in: #{options.backup_dir}")
    end
  end
end
