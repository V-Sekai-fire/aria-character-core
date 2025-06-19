defmodule AriaEngine.MCPTools.VersionManager do
  @moduledoc """
  Manages API versioning for AriaEngine MCP tools.
  """

  @current_api_version "1.0.0"
  @supported_api_versions ["1.0.0"]

  @doc """
  Returns the current API version.
  """
  def current_api_version, do: @current_api_version

  @doc """
  Returns all supported API versions.
  """
  def supported_api_versions, do: @supported_api_versions

  @doc """
  Checks if a given API version is supported.
  """
  def version_supported?(version) when is_binary(version) do
    version in @supported_api_versions
  end

  @doc """
  Validates API version compatibility for a request.
  Returns {:ok, version} or {:error, reason}.
  """
  def validate_api_version(nil), do: {:ok, @current_api_version}
  def validate_api_version(version) when is_binary(version) do
    if version_supported?(version) do
      {:ok, version}
    else
      {:error, "Unsupported API version: #{version}. Supported versions: #{inspect(@supported_api_versions)}"}
    end
  end
  def validate_api_version(_), do: {:error, "API version must be a string"}

  @doc """
  Checks if a tool version is compatible with a requested API version.
  Uses semantic versioning compatibility rules.
  """
  def version_compatible?(tool_version, api_version) when is_binary(tool_version) and is_binary(api_version) do
    # For now, use simple exact matching.
    # In the future, this could implement semantic versioning rules:
    # - Same major version required for compatibility
    # - Minor/patch versions are backward compatible
    tool_version == api_version
  end
end
