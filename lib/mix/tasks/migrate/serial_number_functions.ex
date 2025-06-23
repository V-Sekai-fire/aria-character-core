# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.SerialNumberFunctions do
  @moduledoc """
  Migration tool to add serial_number/0 functions to modules with @serial_number attributes.

  Instead of suppressing warnings, this tool makes @serial_number attributes "used"
  by adding a public function that returns the serial number value.
  """

  use Mix.Task
  alias Mix.Tasks.Migrate.AstTransformer

  require Logger

  @shortdoc "Add serial_number/0 functions to modules with @serial_number attributes"

  @switches [
    dry_run: :boolean,
    help: :boolean
  ]

  @aliases [
    d: :dry_run,
    h: :help
  ]

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      dry_run = opts[:dry_run] || false

      Logger.info("🔧 Serial Number Function Generator")
      Logger.info("==================================")

      if dry_run do
        Logger.info("🔍 DRY RUN MODE - No files will be modified")
      end

      Logger.info("")

      # Find all files with @serial_number attributes
      files_with_serial_numbers = find_files_with_serial_numbers()

      if Enum.empty?(files_with_serial_numbers) do
        Logger.info("✅ No files found with @serial_number attributes")
      else
        Logger.info("📋 Found #{length(files_with_serial_numbers)} files with @serial_number attributes")

        Enum.each(files_with_serial_numbers, fn file ->
          process_file(file, dry_run)
        end)

        Logger.info("")
        Logger.info("✅ Serial number function generation completed!")
      end
    end
  end

  defp show_help do
    IO.puts(@moduledoc)
    IO.puts("""

    ## Usage

        mix migrate.serial_number_functions           # Add serial_number/0 functions
        mix migrate.serial_number_functions --dry-run # Preview changes only
        mix migrate.serial_number_functions --help    # Show this help

    ## What it does

    This tool finds modules with @serial_number attributes and adds:

        @doc "Returns the module's serial number for tracking and identification."
        @spec serial_number() :: String.t()
        def serial_number, do: @serial_number

    This makes the @serial_number attribute "used" by the compiler, eliminating
    warnings while providing a standard API for accessing serial numbers.
    """)
  end

  defp find_files_with_serial_numbers do
    Path.wildcard("**/*.{ex,exs}", match_dot: true)
    |> Enum.filter(&File.exists?/1)
    |> Enum.filter(&should_check_file?/1)
    |> Enum.filter(fn file ->
      content = File.read!(file)
      String.contains?(content, "@serial_number") and
      not String.contains?(content, "def serial_number")
    end)
  end

  defp should_check_file?(file) do
    # Check all lib files, not just membrane
    String.starts_with?(file, "lib/") and
    not String.contains?(file, "_build/") and
    not String.contains?(file, "deps/") and
    not String.contains?(file, ".elixir_ls/")
  end

  defp process_file(file, dry_run) do
    content = File.read!(file)

    case add_serial_number_function(content) do
      {:changed, new_content} ->
        if dry_run do
          Logger.info("   📄 Would add serial_number/0 function to: #{file}")
        else
          File.write!(file, new_content)
          Logger.info("   ✅ Added serial_number/0 function to: #{file}")
        end

      :unchanged ->
        Logger.debug("   ⏭️  Already has serial_number/0 function: #{file}")

      {:error, reason} ->
        Logger.warning("   ❌ Failed to process #{file}: #{reason}")
    end
  end

  defp add_serial_number_function(source_code) do
    # Check if we already have a serial_number function
    if String.contains?(source_code, "def serial_number") do
      :unchanged
    else
      case AstTransformer.parse_code(source_code) do
        {:ok, ast} ->
          transformed_ast = add_serial_number_function_to_ast(ast)
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

  defp add_serial_number_function_to_ast(ast) do
    Macro.prewalk(ast, fn node ->
      case node do
        # Match defmodule and add function after @serial_number
        {:defmodule, meta, [module_name, [do: module_body]]} ->
          case has_serial_number_in_body?(module_body) do
            true ->
              new_body = insert_serial_number_function(module_body)
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
    # Check if the module body contains @serial_number
    body_string = Macro.to_string(module_body)
    String.contains?(body_string, "@serial_number")
  end

  defp insert_serial_number_function(module_body) do
    case module_body do
      # If body is a block, find @serial_number and insert function after it
      {:__block__, meta, statements} ->
        new_statements = insert_function_after_serial_number(statements)
        {:__block__, meta, new_statements}

      # If body is a single statement, check if it's @serial_number
      single_statement ->
        case single_statement do
          {:@, _, [{:serial_number, _, _}]} ->
            # Wrap in block with function
            {:__block__, [], [single_statement | create_serial_number_function()]}
          _ ->
            single_statement
        end
    end
  end

  defp insert_function_after_serial_number(statements) do
    {before_serial, after_serial} = find_serial_number_position(statements)

    case after_serial do
      [] ->
        # @serial_number not found, return original
        statements
      [serial_number_stmt | rest] ->
        # Insert function after @serial_number
        before_serial ++ [serial_number_stmt] ++ create_serial_number_function() ++ rest
    end
  end

  defp find_serial_number_position(statements) do
    Enum.split_while(statements, fn stmt ->
      case stmt do
        {:@, _, [{:serial_number, _, _}]} -> false
        _ -> true
      end
    end)
  end

  defp create_serial_number_function do
    [
      # @doc "Returns the module's serial number for tracking and identification."
      {:@, [], [
        {:doc, [], ["Returns the module's serial number for tracking and identification."]}
      ]},

      # @spec serial_number() :: String.t()
      {:@, [], [
        {:spec, [], [
          {:":::", [], [
            {:serial_number, [], []},
            {{:., [], [{:__aliases__, [], [:String]}, :t]}, [], []}
          ]}
        ]}
      ]},

      # def serial_number, do: @serial_number
      {:def, [], [
        {:serial_number, [], []},
        [do: {:@, [], [{:serial_number, [], nil}]}]
      ]}
    ]
  end

  @doc """
  Remove old @compile directives for serial_number warnings.

  This function can be used to clean up old warning suppression directives
  since we're now making the attributes "used" instead.
  """
  def remove_old_compile_directives(source_code) do
    case AstTransformer.parse_code(source_code) do
      {:ok, ast} ->
        cleaned_ast = remove_serial_number_compile_directives(ast)
        case AstTransformer.ast_to_code(cleaned_ast) do
          {:ok, new_code} -> {:ok, new_code}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp remove_serial_number_compile_directives(ast) do
    Macro.prewalk(ast, fn node ->
      case node do
        # Remove @compile {:no_warn_unused, [:serial_number]}
        {:@, _, [{:compile, _, [{:{}, _, [:no_warn_unused, [:serial_number]]}]}]} ->
          nil

        # Remove @compile {:no_warn_unused, [:serial_number]} (different AST format)
        {:@, _, [{:compile, _, [no_warn_unused: [:serial_number]]}]} ->
          nil

        _ ->
          node
      end
    end)
    |> remove_nil_nodes()
  end

  defp remove_nil_nodes(ast) do
    Macro.prewalk(ast, fn node ->
      case node do
        {:__block__, meta, statements} ->
          filtered_statements = Enum.reject(statements, &is_nil/1)
          {:__block__, meta, filtered_statements}
        _ ->
          node
      end
    end)
  end
end
