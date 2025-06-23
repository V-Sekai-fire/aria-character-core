defmodule AstMigrate.Parser do
  @moduledoc "Advanced AST parsing using Sourceror for robust code transformation.\n\nThis module provides enhanced AST parsing capabilities beyond the basic\nCode.string_to_quoted/2, including:\n- Preservation of comments and formatting\n- Better error handling and recovery\n- Source location tracking\n- Whitespace preservation for minimal diffs\n"
  require Logger
  @type parse_result :: {:ok, Sourceror.Zipper.t()} | {:error, String.t()}
  @type transform_result :: {:ok, String.t()} | {:error, String.t()}
  @doc "Parse Elixir source code into a Sourceror zipper for advanced manipulation.\n\n## Options\n\n- `:preserve_comments` - Keep comments in the AST (default: true)\n- `:preserve_formatting` - Maintain original formatting (default: true)\n- `:error_recovery` - Attempt to recover from parse errors (default: true)\n\n## Examples\n\n    iex> AstMigrate.Parser.parse_file(\"lib/my_module.ex\")\n    {:ok, %Sourceror.Zipper{}}\n\n    iex> AstMigrate.Parser.parse_string(\"defmodule Test, do: :ok\")\n    {:ok, %Sourceror.Zipper{}}\n"
  @spec parse_file(String.t(), keyword()) :: parse_result()
  def parse_file(file_path, opts \\ []) do
    Logger.debug("Parsing file with Sourceror",
      module: :ast_migrate_parser,
      operation: :parse_file,
      file: file_path,
      options: opts
    )

    with {:ok, content} <- File.read(file_path),
         {:ok, zipper} <- parse_string(content, opts) do
      Logger.debug("File parsed successfully",
        module: :ast_migrate_parser,
        operation: :parse_file,
        file: file_path,
        content_size: byte_size(content)
      )

      {:ok, zipper}
    else
      {:error, reason} ->
        Logger.error("Failed to parse file",
          module: :ast_migrate_parser,
          operation: :parse_file,
          file: file_path,
          error: inspect(reason)
        )

        {:error, "Failed to parse #{file_path}: #{inspect(reason)}"}
    end
  end

  @doc "Parse Elixir source code string into a Sourceror zipper.\n"
  @spec parse_string(String.t(), keyword()) :: parse_result()
  def parse_string(content, opts \\ []) do
    options = Keyword.merge(default_parse_options(), opts)

    Logger.debug("Parsing string with Sourceror",
      module: :ast_migrate_parser,
      operation: :parse_string,
      content_size: byte_size(content),
      options: options
    )

    try do
      case Sourceror.parse_string(content, options) do
        {:ok, ast} ->
          zipper = Sourceror.Zipper.zip(ast)

          Logger.debug("String parsed successfully",
            module: :ast_migrate_parser,
            operation: :parse_string,
            content_size: byte_size(content)
          )

          {:ok, zipper}

        {:error, reason} ->
          Logger.warning("Parse error with Sourceror",
            module: :ast_migrate_parser,
            operation: :parse_string,
            error: inspect(reason),
            content_preview: String.slice(content, 0, 100)
          )

          fallback_parse(content)
      end
    rescue
      exception ->
        Logger.error("Exception during Sourceror parsing",
          module: :ast_migrate_parser,
          operation: :parse_string,
          exception: inspect(exception),
          content_preview: String.slice(content, 0, 100)
        )

        fallback_parse(content)
    end
  end

  @doc "Convert a Sourceror zipper back to formatted source code.\n\n## Options\n\n- `:preserve_formatting` - Maintain original formatting (default: true)\n- `:format_code` - Apply Elixir formatter (default: false)\n"
  @spec to_string(Sourceror.Zipper.t(), keyword()) :: transform_result()
  def to_string(zipper, opts \\ []) do
    options = Keyword.merge(default_format_options(), opts)

    Logger.debug("Converting zipper to string",
      module: :ast_migrate_parser,
      operation: :to_string,
      options: options
    )

    try do
      ast = Sourceror.Zipper.root(zipper)

      code =
        if options[:format_code] do
          ast |> Sourceror.to_string() |> Code.format_string!() |> IO.iodata_to_binary()
        else
          Sourceror.to_string(ast)
        end

      Logger.debug("Zipper converted to string successfully",
        module: :ast_migrate_parser,
        operation: :to_string,
        output_size: byte_size(code)
      )

      {:ok, code}
    rescue
      exception ->
        Logger.error("Exception during zipper to string conversion",
          module: :ast_migrate_parser,
          operation: :to_string,
          exception: inspect(exception)
        )

        {:error, "Failed to convert AST to string: #{inspect(exception)}"}
    end
  end

  @doc "Apply a transformation function to a zipper while preserving structure.\n\nThe transformation function receives a zipper and should return a modified zipper.\n"
  @spec transform(Sourceror.Zipper.t(), (Sourceror.Zipper.t() -> Sourceror.Zipper.t())) ::
          Sourceror.Zipper.t()
  def transform(zipper, transform_fn) when is_function(transform_fn, 1) do
    Logger.debug("Applying transformation to zipper",
      module: :ast_migrate_parser,
      operation: :transform
    )

    try do
      result = transform_fn.(zipper)

      Logger.debug("Transformation applied successfully",
        module: :ast_migrate_parser,
        operation: :transform
      )

      result
    rescue
      exception ->
        Logger.error("Exception during transformation",
          module: :ast_migrate_parser,
          operation: :transform,
          exception: inspect(exception)
        )

        zipper
    end
  end

  @doc "Find all nodes in the zipper that match a given pattern.\n\n## Examples\n\n    # Find all function definitions\n    AstMigrate.Parser.find_nodes(zipper, fn\n      {:def, _, _} -> true\n      _ -> false\n    end)\n\n    # Find all StateV2 references\n    AstMigrate.Parser.find_nodes(zipper, fn\n      {:__aliases__, _, [:StateV2]} -> true\n      {:__aliases__, _, [:AriaEngine, :StateV2]} -> true\n      _ -> false\n    end)\n"
  @spec find_nodes(Sourceror.Zipper.t(), (term() -> boolean())) :: [Sourceror.Zipper.t()]
  def find_nodes(zipper, matcher_fn) when is_function(matcher_fn, 1) do
    Logger.debug("Finding nodes in zipper", module: :ast_migrate_parser, operation: :find_nodes)

    results =
      Sourceror.Zipper.traverse(zipper, [], fn zipper, acc ->
        node = Sourceror.Zipper.node(zipper)

        if matcher_fn.(node) do
          {zipper, [zipper | acc]}
        else
          {zipper, acc}
        end
      end)

    matches = elem(results, 1) |> Enum.reverse()

    Logger.debug("Node search completed",
      module: :ast_migrate_parser,
      operation: :find_nodes,
      matches_found: length(matches)
    )

    matches
  end

  @doc "Replace all nodes that match a pattern with the result of a transformation function.\n"
  @spec replace_nodes(Sourceror.Zipper.t(), (term() -> boolean()), (Sourceror.Zipper.t() ->
                                                                      term())) ::
          Sourceror.Zipper.t()
  def replace_nodes(zipper, matcher_fn, replacer_fn)
      when is_function(matcher_fn, 1) and is_function(replacer_fn, 1) do
    Logger.debug("Replacing nodes in zipper",
      module: :ast_migrate_parser,
      operation: :replace_nodes
    )

    replacement_count = 0

    {result_zipper, final_count} =
      Sourceror.Zipper.traverse(zipper, replacement_count, fn zipper, count ->
        node = Sourceror.Zipper.node(zipper)

        if matcher_fn.(node) do
          new_node = replacer_fn.(zipper)
          new_zipper = Sourceror.Zipper.replace(zipper, new_node)
          {new_zipper, count + 1}
        else
          {zipper, count}
        end
      end)

    Logger.debug("Node replacement completed",
      module: :ast_migrate_parser,
      operation: :replace_nodes,
      replacements_made: final_count
    )

    result_zipper
  end

  defp default_parse_options do
    [
      preserve_comments: true,
      token_metadata: true,
      literal_encoder: &{:ok, {:__block__, &2, [&1]}}
    ]
  end

  defp default_format_options do
    [preserve_formatting: true, format_code: false]
  end

  defp fallback_parse(content) do
    Logger.debug("Attempting fallback parse with Code.string_to_quoted",
      module: :ast_migrate_parser,
      operation: :fallback_parse
    )

    case Code.string_to_quoted(content) do
      {:ok, ast} ->
        zipper = Sourceror.Zipper.zip(ast)

        Logger.debug("Fallback parse successful",
          module: :ast_migrate_parser,
          operation: :fallback_parse
        )

        {:ok, zipper}

      {:error, reason} ->
        Logger.error("Fallback parse failed",
          module: :ast_migrate_parser,
          operation: :fallback_parse,
          error: inspect(reason)
        )

        {:error, "Parse failed: #{inspect(reason)}"}
    end
  end
end