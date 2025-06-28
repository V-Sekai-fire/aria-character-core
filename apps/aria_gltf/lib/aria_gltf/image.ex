# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf.Image do
  @moduledoc """
  Mock implementation of AriaGltf.Image for compilation.

  This module represents glTF image data and URI references.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: %__MODULE__{
    uri: String.t() | nil,
    mime_type: String.t() | nil,
    buffer_view: non_neg_integer() | nil,
    name: String.t() | nil
  }

  defstruct [:uri, :mime_type, :buffer_view, :name]

  @doc """
  Create a new image from JSON data.
  """
  @spec from_json(map()) :: t()
  def from_json(json) when is_map(json) do
    %__MODULE__{
      uri: Map.get(json, "uri"),
      mime_type: Map.get(json, "mimeType"),
      buffer_view: Map.get(json, "bufferView"),
      name: Map.get(json, "name")
    }
  end

  @doc """
  Convert image to JSON representation.
  """
  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = image) do
    %{}
    |> maybe_put("uri", image.uri)
    |> maybe_put("mimeType", image.mime_type)
    |> maybe_put("bufferView", image.buffer_view)
    |> maybe_put("name", image.name)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
