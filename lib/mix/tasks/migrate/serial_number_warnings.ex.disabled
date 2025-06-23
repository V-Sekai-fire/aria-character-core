# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.SerialNumberWarnings do
  @moduledoc "Migration tool to suppress unused @serial_number warnings.\n\nAdds @compile {:no_warn_unused, [:serial_number]} directive to modules\nthat have @serial_number attributes to suppress compiler warnings.\n"
  use Mix.Task
  alias Mix.Tasks.Migrate.AstTransformer
  require Logger
  @shortdoc "Suppress unused @serial_number warnings with compile directives"
  @switches dry_run: :boolean, help: :boolean
  @aliases d: :dry_run, h: :help
  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      dry_run = opts[:dry_run] || false
      Logger.info("🔧 Serial Number Warning Suppression Tool")
      Logger.info("==========================================")

      if dry_run do
        Logger.info("🔍 DRY RUN MODE - No files will be modified")
      end

      Logger.info("")
      files_with_serial_numbers = find_files_with_serial_numbers()

      if Enum.empty?(files_with_serial_numbers) do
        Logger.info("✅ No files found with @serial_number attributes")
      else
        Logger.info(
          "📋 Found #{length(files_with_serial_numbers)} files with @serial_number attributes"
        )

        Enum.each(files_with_serial_numbers, fn file -> process_file(file, dry_run) end)
        Logger.info("")
        Logger.info("✅ Serial number warning suppression completed!")
      end
    end
  end

  defp show_help do
    IO.puts(@moduledoc)

    IO.puts(
      "\n## Usage\n\n    mix migrate.serial_number_warnings           # Add compile directives\n    mix migrate.serial_number_warnings --dry-run # Preview changes only\n    mix migrate.serial_number_warnings --help    # Show this help\n\n## What it does\n\nThis tool finds modules with @serial_number attributes and adds:\n\n    @compile {:no_warn_unused, [:serial_number]}\n\nThis suppresses Elixir's \"unused module attribute\" warnings while\npreserving the serial number functionality for tracking purposes.\n"
    )
  end

  defp find_files_with_serial_numbers do
    Path.wildcard("**/*.{ex,exs}", match_dot: true)
    |> Enum.filter(&File.exists?/1)
    |> Enum.filter(&should_check_file?/1)
    |> Enum.filter(fn file ->
      content = File.read!(file)
      String.contains?(content, "@serial_number")
    end)
  end

  defp should_check_file?(file) do
    String.contains?(file, "lib/aria_engine/membrane/") and not String.contains?(file, "_build/") and
      not String.contains?(file, "deps/") and not String.contains?(file, ".elixir_ls/")
  end

  defp process_file(file, dry_run) do
    content = File.read!(file)

    case add_compile_directive(content) do
      {:changed, new_content} ->
        if dry_run do
          Logger.info("   📄 Would add compile directive to: #{file}")
        else
          File.write!(file, new_content)
          Logger.info("   ✅ Added compile directive to: #{file}")
        end

      :unchanged ->
        Logger.debug("   ⏭️  Already has compile directive: #{file}")

      {:error, reason} ->
        Logger.warning("   ❌ Failed to process #{file}: #{reason}")
    end
  end

  defp add_compile_directive(source_code) do
    has_proper_directive =
      String.contains?(source_code, "@compile {:no_warn_unused, [:serial_number]}") or
        String.contains?(source_code, "@compile :no_warn_unused")

    has_duplicate_moduledoc = count_moduledoc_occurrences(source_code) > 1

    if has_proper_directive and not has_duplicate_moduledoc do
      :unchanged
    else
      case AstTransformer.parse_code(source_code) do
        {:ok, ast} ->
          cleaned_ast =
            if has_duplicate_moduledoc do
              clean_duplicate_moduledoc(ast)
            else
              ast
            end

          transformed_ast = add_compile_directive_to_ast(cleaned_ast)

          case AstTransformer.ast_to_code(transformed_ast) do
            {:ok, new_code} ->
              if new_code == source_code do
                :unchanged
              else
                {:changed, new_code}
              end

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp add_compile_directive_to_ast(ast) do
    Macro.prewalk(ast, fn node ->
      case node do
        {:defmodule, meta, [module_name, [do: module_body]]} ->
          case has_serial_number_in_body?(module_body) do
            true ->
              compile_directive = create_compile_directive()
              new_body = insert_compile_directive(module_body, compile_directive)
              {:defmodule, meta, [module_name, [do: new_body]]}

            false ->
              node
          end

        _ ->
          node
      end
    end)
  end

  defp has_serial_number_in_body?(module_body) do
    body_string = Macro.to_string(module_body)
    String.contains?(body_string, "@serial_number")
  end

  defp create_compile_directive do
    {:@, [], [{:compile, [], [{:{}, [], [:no_warn_unused, [:serial_number]]}]}]}
  end

  defp insert_compile_directive(module_body, compile_directive) do
    case module_body do
      {:__block__, meta, statements} ->
        {before_compile, after_compile} = split_at_compile_directives(statements)
        new_statements = before_compile ++ [compile_directive] ++ after_compile
        {:__block__, meta, new_statements}

      single_statement ->
        {:__block__, [], [compile_directive, single_statement]}
    end
  end

  defp split_at_compile_directives(statements) do
    Enum.split_while(statements, fn stmt ->
      case stmt do
        {:@, _, [{:compile, _, _}]} -> true
        {:@, _, _} -> false
        {:def, _, _} -> false
        {:defp, _, _} -> false
        _ -> true
      end
    end)
  end

  defp count_moduledoc_occurrences(source_code) do
    source_code
    |> String.split("\n")
    |> Enum.count(fn line ->
      String.contains?(line, "@moduledoc") and not String.contains?(line, "#")
    end)
  end

  defp clean_duplicate_moduledoc(ast) do
    Macro.prewalk(ast, fn node ->
      case node do
        {:defmodule, meta, [module_name, [do: module_body]]} ->
          cleaned_body = remove_duplicate_moduledoc(module_body)
          {:defmodule, meta, [module_name, [do: cleaned_body]]}

        _ ->
          node
      end
    end)
  end

  defp remove_duplicate_moduledoc(module_body) do
    case module_body do
      {:__block__, meta, statements} ->
        {compile_statements, other_statements} =
          Enum.split_with(statements, fn stmt ->
            case stmt do
              {:@, _, [{:compile, _, _}]} -> true
              {:@, _, [{:moduledoc, _, _}]} -> true
              _ -> false
            end
          end)

        moduledoc_statements =
          Enum.filter(compile_statements, fn stmt ->
            case stmt do
              {:@, _, [{:moduledoc, _, _}]} -> true
              _ -> false
            end
          end)

        final_moduledoc =
          case moduledoc_statements do
            [] -> []
            [single] -> [single]
            multiple -> [List.last(multiple)]
          end

        new_statements = other_statements ++ final_moduledoc
        {:__block__, meta, new_statements}

      single_statement ->
        single_statement
    end
  end
end
