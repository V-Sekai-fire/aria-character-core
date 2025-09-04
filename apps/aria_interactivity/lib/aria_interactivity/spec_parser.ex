defmodule AriaInteractivity.SpecParser do
  @moduledoc """
  Parser for glTF Interactivity Extension Specification

  This module handles parsing the AsciiDoc specification file
  and extracting node definitions for use in the planning domain.
  """

  @spec_file_path "apps/aria_gltf/thirdparty/Specification.adoc"

  @doc """
  Read the glTF interactivity specification file.
  """
  def read_specification do
    case File.read(@spec_file_path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, "Failed to read spec file: #{reason}"}
    end
  end

  @doc """
  Extract node definitions from the specification.
  """
  def extract_nodes do
    with {:ok, content} <- read_specification() do
      # Parse the AsciiDoc content to extract node definitions
      nodes = parse_nodes_from_content(content)
      {:ok, nodes}
    end
  end

  defp parse_nodes_from_content(content) do
    # Simple parsing - look for node operation patterns
    # This is a basic implementation that will be refined

    # Find sections that define nodes
    node_sections = extract_node_sections(content)

    # Parse each section into node definitions
    Enum.map(node_sections, &parse_node_section/1)
  end

  defp extract_node_sections(content) do
    # Split content by headers and find node definition sections
    sections = String.split(content, "\n==")

    # Filter for sections that contain node definitions
    Enum.filter(sections, fn section ->
      String.contains?(section, "Operation") &&
      (String.contains?(section, "math/") || String.contains?(section, "flow/") ||
       String.contains?(section, "event/") || String.contains?(section, "pointer/"))
    end)
  end

  defp parse_node_section(section) do
    # Extract operation name
    operation = extract_operation(section)

    # Create a basic node structure
    %{
      name: operation,
      operation: operation,
      description: extract_description(section),
      inputs: extract_inputs(section),
      outputs: extract_outputs(section)
    }
  end

  defp extract_operation(section) do
    # Look for the operation pattern like `math/add`
    case Regex.run(~r/Operation.*?\* ([a-zA-Z0-9_\/]+)\*/, section) do
      [_, operation] -> operation
      nil ->
        # Fallback: look for other patterns
        case Regex.run(~r/Operation.*?\* `([a-zA-Z0-9_\/]+)`/, section) do
          [_, operation] -> operation
          nil -> "unknown_operation"
        end
    end
  end

  defp extract_description(section) do
    # Extract the first paragraph after the operation
    lines = String.split(section, "\n")
    description_lines = Enum.take_while(lines, fn line ->
      !String.starts_with?(line, "Input value sockets") &&
      !String.starts_with?(line, "Output value sockets") &&
      !String.starts_with?(line, "Output flow sockets") &&
      String.trim(line) != ""
    end)

    Enum.join(description_lines, " ")
  end

  defp extract_inputs(section) do
    # Simple extraction - this will be refined
    []
  end

  defp extract_outputs(section) do
    # Simple extraction - this will be refined
    []
  end
end
