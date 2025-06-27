# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.Adrs do
  @moduledoc """
  Migrate ADR files to use aria_serial naming convention.

  This task:
  1. Generates serial numbers for all ADR files
  2. Renames files to use serial-based naming
  3. Updates cross-references throughout the codebase
  4. Creates backup of original files

  ## Usage

      mix migrate.adrs
      mix migrate.adrs --dir decisions/
      mix migrate.adrs --dry-run

  ## Process

  1. **Generate Serials**: Creates industrial-grade serial numbers for each ADR
  2. **Create Mapping**: Builds old-filename → new-filename mapping
  3. **Rename Files**: Moves ADR files to new serial-based names
  4. **Update References**: Finds and updates all cross-references in codebase
  5. **Update Rules**: Updates .clinerules to reference aria_serial for ADR naming

  ## Examples

      # Migrate all ADRs with preview
      mix migrate.adrs --dry-run

      # Execute migration
      mix migrate.adrs

      # Migrate specific directory
      mix migrate.adrs --dir decisions/
  """

  use Mix.Task
  require Logger

  @shortdoc "Migrate ADR files to aria_serial naming convention"
  @switches [
    dry_run: :boolean,
    help: :boolean,
    dir: :string
  ]
  @aliases [d: :dry_run, h: :help]

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      migrate_adrs(opts)
    end
  end

  defp migrate_adrs(opts) do
    dry_run = opts[:dry_run] || false
    adr_dir = opts[:dir] || "decisions"

    Mix.shell().info("🔄 ADR Migration to aria_serial naming convention")
    Mix.shell().info("Directory: #{adr_dir}")
    Mix.shell().info("Mode: #{if dry_run, do: "DRY RUN", else: "LIVE"}")
    Mix.shell().info("")

    with {:ok, mapping} <- generate_migration_mapping(adr_dir, dry_run),
         :ok <- validate_migration(mapping, dry_run),
         :ok <- execute_migration(mapping, adr_dir, dry_run),
         :ok <- update_cross_references(mapping, dry_run),
         :ok <- update_clinerules(dry_run) do

      if dry_run do
        Mix.shell().info("✅ DRY RUN completed successfully")
        Mix.shell().info("Run without --dry-run to execute migration")
      else
        Mix.shell().info("✅ ADR migration completed successfully!")
        Mix.shell().info("All ADR files now use aria_serial naming convention")
      end
    else
      {:error, reason} ->
        Mix.shell().error("❌ Migration failed: #{reason}")
        {:error, reason}
    end
  end

  defp generate_migration_mapping(adr_dir, dry_run) do
    Mix.shell().info("📋 Step 1: Generating serial numbers and mapping...")

    # Use the existing ADR serial generation task
    case System.cmd("mix", ["generate.adr.serial", "--dir", adr_dir, "--create-mapping"] ++
                           (if dry_run, do: ["--dry-run"], else: []),
                    stderr_to_stdout: true) do
      {_output, 0} ->
        mapping_file = "adr_migration_mapping.json"

        # Try to load from JSON storage first, fallback to temporary file
        case load_mapping_from_storage() do
          {:ok, mapping} ->
            Mix.shell().info("   ✅ Loaded mapping from serial registry for #{length(mapping)} ADR files")
            {:ok, mapping}
          {:error, _} ->
            # Fallback to temporary mapping file
            if File.exists?("adr_migration_mapping.json") do
              case File.read(mapping_file) do
                {:ok, content} ->
                  case Jason.decode(content) do
                    {:ok, mapping} ->
                      Mix.shell().info("   ✅ Generated mapping for #{length(mapping)} ADR files")
                      {:ok, mapping}
                    {:error, reason} ->
                      {:error, "Failed to parse mapping file: #{reason}"}
                  end
                {:error, reason} ->
                  {:error, "Failed to read mapping file: #{reason}"}
              end
            else
              {:error, "Mapping file not created"}
            end
        end

      {output, exit_code} ->
        Mix.shell().error("Serial generation failed (exit #{exit_code}):")
        Mix.shell().error(output)
        {:error, "Serial generation failed"}
    end
  end

  defp validate_migration(mapping, _dry_run) do
    Mix.shell().info("🔍 Step 2: Validating migration plan...")

    # Check for potential conflicts
    new_filenames = Enum.map(mapping, & &1["new_filename"])
    duplicates = new_filenames -- Enum.uniq(new_filenames)

    if Enum.empty?(duplicates) do
      Mix.shell().info("   ✅ No filename conflicts detected")

      # Show sample mappings
      Mix.shell().info("   📝 Sample mappings:")
      mapping
      |> Enum.take(5)
      |> Enum.each(fn entry ->
        Mix.shell().info("      #{entry["old_filename"]} → #{entry["new_filename"]}")
      end)

      if length(mapping) > 5 do
        Mix.shell().info("      ... and #{length(mapping) - 5} more files")
      end

      :ok
    else
      {:error, "Duplicate filenames detected: #{inspect(duplicates)}"}
    end
  end

  defp execute_migration(mapping, adr_dir, dry_run) do
    Mix.shell().info("📁 Step 3: Renaming ADR files...")

    if dry_run do
      Mix.shell().info("   [DRY RUN] Would rename #{length(mapping)} files")
      :ok
    else
      # Create backup directory
      backup_dir = "#{adr_dir}_backup_#{DateTime.utc_now() |> DateTime.to_unix()}"
      File.mkdir_p!(backup_dir)
      Mix.shell().info("   📦 Created backup directory: #{backup_dir}")

      # Process each file
      results = Enum.map(mapping, fn entry ->
        old_path = Path.join(adr_dir, entry["old_filename"])
        new_path = Path.join(adr_dir, entry["new_filename"])
        backup_path = Path.join(backup_dir, entry["old_filename"])

        with {:ok, _} <- File.copy(old_path, backup_path),
             :ok <- File.rename(old_path, new_path) do
          Mix.shell().info("   ✅ #{entry["old_filename"]} → #{entry["new_filename"]}")
          :ok
        else
          {:error, reason} ->
            Mix.shell().error("   ❌ Failed to rename #{entry["old_filename"]}: #{reason}")
            {:error, reason}
        end
      end)

      # Check if all succeeded
      case Enum.find(results, &match?({:error, _}, &1)) do
        nil -> :ok
        {:error, reason} -> {:error, "File renaming failed: #{reason}"}
      end
    end
  end

  defp update_cross_references(mapping, dry_run) do
    Mix.shell().info("🔗 Step 4: Updating cross-references...")

    # Build reference mapping
    ref_mapping =
      mapping
      |> Enum.map(fn entry ->
        old_ref = Path.basename(entry["old_filename"], ".md")
        new_ref = Path.basename(entry["new_filename"], ".md")
        {old_ref, new_ref}
      end)
      |> Map.new()

    # Find all files that might contain references
    search_patterns = [
      "**/*.md",
      "**/*.ex",
      "**/*.exs",
      "**/*.txt",
      ".clinerules/**/*.md"
    ]

    files_to_update =
      search_patterns
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.uniq()
      |> Enum.filter(&File.regular?/1)

    Mix.shell().info("   🔍 Scanning #{length(files_to_update)} files for references...")

    if dry_run do
      # Just count potential updates
      update_count = count_potential_updates(files_to_update, ref_mapping)
      Mix.shell().info("   [DRY RUN] Would update approximately #{update_count} references")
      :ok
    else
      update_count = update_references_in_files(files_to_update, ref_mapping)
      Mix.shell().info("   ✅ Updated #{update_count} references across codebase")
      :ok
    end
  end

  defp count_potential_updates(files, ref_mapping) do
    files
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          Enum.count(ref_mapping, fn {old_ref, _new_ref} ->
            String.contains?(content, old_ref)
          end)
        {:error, _} -> 0
      end
    end)
    |> Enum.sum()
  end

  defp update_references_in_files(files, ref_mapping) do
    files
    |> Enum.map(&update_references_in_file(&1, ref_mapping))
    |> Enum.sum()
  end

  defp update_references_in_file(file_path, ref_mapping) do
    case File.read(file_path) do
      {:ok, content} ->
        {new_content, update_count} =
          Enum.reduce(ref_mapping, {content, 0}, fn {old_ref, new_ref}, {acc_content, acc_count} ->
            if String.contains?(acc_content, old_ref) do
              updated_content = String.replace(acc_content, old_ref, new_ref)
              changes = length(String.split(acc_content, old_ref)) - 1
              {updated_content, acc_count + changes}
            else
              {acc_content, acc_count}
            end
          end)

        if update_count > 0 do
          case File.write(file_path, new_content) do
            :ok ->
              Mix.shell().info("   📝 Updated #{update_count} references in #{Path.relative_to_cwd(file_path)}")
              update_count
            {:error, reason} ->
              Mix.shell().error("   ❌ Failed to update #{file_path}: #{reason}")
              0
          end
        else
          0
        end

      {:error, _reason} ->
        0
    end
  end

  defp update_clinerules(dry_run) do
    Mix.shell().info("📋 Step 5: Updating .clinerules for aria_serial usage...")

    clinerules_file = ".clinerules/Process ADRs.instructions.md"

    if File.exists?(clinerules_file) do
      case File.read(clinerules_file) do
        {:ok, content} ->
          # Add aria_serial reference to the ADR process
          updated_content = add_aria_serial_reference(content)

          if dry_run do
            Mix.shell().info("   [DRY RUN] Would update #{clinerules_file}")
            :ok
          else
            case File.write(clinerules_file, updated_content) do
              :ok ->
                Mix.shell().info("   ✅ Updated #{clinerules_file}")
                :ok
              {:error, reason} ->
                {:error, "Failed to update clinerules: #{reason}"}
            end
          end

        {:error, reason} ->
          {:error, "Failed to read clinerules file: #{reason}"}
      end
    else
      Mix.shell().info("   ⚠️  Clinerules file not found: #{clinerules_file}")
      :ok
    end
  end

  defp load_mapping_from_storage do
    # Try to find the most recent ADR migration registry file
    current_date = Date.utc_today()
    year = current_date.year
    week = div(Date.day_of_year(current_date), 7) + 1

    storage_path = "apps/aria_serial/priv/serial_data/#{year}/week_#{week}/R_series_adr_migration.json"

    if File.exists?(storage_path) do
      case File.read(storage_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, registry_data} ->
              # Convert registry format back to mapping format
              mapping =
                registry_data["serials"]
                |> Enum.map(fn {serial, entry} ->
                  %{
                    "old_filename" => entry["old_filename"],
                    "new_filename" => entry["new_filename"],
                    "serial" => serial,
                    "title" => String.replace(entry["purpose"], "ADR Migration: ", ""),
                    "creation_date" => entry["created"]
                  }
                end)
              {:ok, mapping}
            {:error, reason} ->
              {:error, "Failed to decode registry: #{reason}"}
          end
        {:error, reason} ->
          {:error, "Failed to read registry: #{reason}"}
      end
    else
      {:error, "No ADR migration registry found"}
    end
  end

  defp add_aria_serial_reference(content) do
    # Add a section about using aria_serial for ADR naming
    aria_serial_section = """

### ADR Naming Convention

All new ADRs must use aria_serial for consistent naming:

```bash
# Generate serial for new ADR
mix generate.adr.serial --file decisions/new-adr.md

# Migrate existing ADRs
mix migrate.adrs
```

ADR files follow the format: `[SERIAL]-[descriptive-name].md`
where SERIAL is generated by aria_serial based on creation date and content.
"""

    # Insert after the main header if not already present
    if String.contains?(content, "aria_serial") do
      content
    else
      # Find a good insertion point
      lines = String.split(content, "\n")
      case Enum.find_index(lines, &String.starts_with?(&1, "## ")) do
        nil ->
          content <> aria_serial_section
        index ->
          {before, after_lines} = Enum.split(lines, index)
          (before ++ [aria_serial_section] ++ after_lines) |> Enum.join("\n")
      end
    end
  end

  defp show_help do
    Mix.shell().info(@moduledoc)
  end
end
