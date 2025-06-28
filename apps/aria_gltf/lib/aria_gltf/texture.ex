defmodule AriaGltf.Texture do
  @moduledoc """
  Mock implementation of AriaGltf.Texture for compilation.

  This module represents glTF texture definitions.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: %__MODULE__{
    sampler: non_neg_integer() | nil,
    source: non_neg_integer() | nil,
    name: String.t() | nil
  }

  defstruct [:sampler, :source, :name]

  @doc """
  Create a new texture from JSON data.
  """
  @spec from_json(map()) :: t()
  def from_json(json) when is_map(json) do
    %__MODULE__{
      sampler: Map.get(json, "sampler"),
      source: Map.get(json, "source"),
      name: Map.get(json, "name")
    }
  end

  @doc """
  Convert texture to JSON representation.
  """
  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = texture) do
    %{}
    |> maybe_put("sampler", texture.sampler)
    |> maybe_put("source", texture.source)
    |> maybe_put("name", texture.name)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
