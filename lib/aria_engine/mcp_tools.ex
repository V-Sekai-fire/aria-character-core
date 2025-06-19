defmodule AriaEngine.MCPTools do
  @moduledoc """
  Shared MCP tool definitions and handlers for AriaEngine.

  This module provides a registry-based system for MCP tools that can be
  used by different MCP server implementations (stdio, HTTP, etc.).

  This module acts as a facade, delegating functionality to specialized modules.
  """

  require Logger

  @doc """
  Returns the current API version.
  """
  def current_api_version, do: AriaEngine.MCPTools.VersionManager.current_api_version()

  @doc """
  Returns all supported API versions.
  """
  def supported_api_versions, do: AriaEngine.MCPTools.VersionManager.supported_api_versions()

  @doc """
  Checks if a given API version is supported.
  """
  def version_supported?(version) do
    AriaEngine.MCPTools.VersionManager.version_supported?(version)
  end

  @doc """
  Validates API version compatibility for a request.
  Returns {:ok, version} or {:error, reason}.
  """
  def validate_api_version(version) do
    AriaEngine.MCPTools.VersionManager.validate_api_version(version)
  end

  @doc """
  Checks if a tool version is compatible with a requested API version.
  Uses semantic versioning compatibility rules.
  """
  def version_compatible?(tool_version, api_version) do
    AriaEngine.MCPTools.VersionManager.version_compatible?(tool_version, api_version)
  end

  @doc """
  Returns all available tool definitions for the current API version.
  """
  def get_all_tools do
    AriaEngine.MCPTools.Registry.get_all_tools()
  end

  @doc """
  Returns all available tool definitions for a specific API version.
  """
  def get_all_tools(api_version) do
    AriaEngine.MCPTools.Registry.get_all_tools(api_version)
  end

  @doc """
  Returns a specific tool definition by name for the current API version.
  """
  def get_tool_definition(tool_name) do
    AriaEngine.MCPTools.Registry.get_tool_definition(tool_name)
  end

  @doc """
  Returns a specific tool definition by name for a specific API version.
  """
  def get_tool_definition(tool_name, api_version) do
    AriaEngine.MCPTools.Registry.get_tool_definition(tool_name, api_version)
  end

  @doc """
  Handles any tool call by routing to the appropriate handler function.
  """
  def handle_tool_call(tool_name, params) do
    AriaEngine.MCPTools.Handlers.handle_tool_call(tool_name, params)
  end
end
