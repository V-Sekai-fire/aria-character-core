defmodule AriaGltf.Camera do
  @moduledoc """
  Mock implementation of AriaGltf.Camera for compilation.

  This module represents glTF camera definitions.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: %__MODULE__{
    orthographic: map() | nil,
    perspective: map() | nil,
    type: String.t(),
    name: String.t() | nil
  }

  defstruct [:orthographic, :perspective, :type, :name]

  @doc """
  Create a new camera from JSON data.
  """
  @spec from_json(map()) :: t()
  def from_json(json) when is_map(json) do
    %__MODULE__{
      orthographic: Map.get(json, "orthographic"),
      perspective: Map.get(json, "perspective"),
      type: Map.get(json, "type"),
      name: Map.get(json, "name")
    }
  end

  @doc """
  Convert camera to JSON representation.
  """
  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = camera) do
    %{}
    |> maybe_put("orthographic", camera.orthographic)
    |> maybe_put("perspective", camera.perspective)
    |> maybe_put("type", camera.type)
    |> maybe_put("name", camera.name)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
