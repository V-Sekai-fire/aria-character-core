defmodule AriaGltf.Skin do
  @moduledoc """
  Mock implementation of AriaGltf.Skin for compilation.

  This module represents glTF skeletal animation support.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: %__MODULE__{
    inverse_bind_matrices: non_neg_integer() | nil,
    skeleton: non_neg_integer() | nil,
    joints: [non_neg_integer()],
    name: String.t() | nil
  }

  defstruct [:inverse_bind_matrices, :skeleton, :joints, :name]

  @doc """
  Create a new skin from JSON data.
  """
  @spec from_json(map()) :: t()
  def from_json(json) when is_map(json) do
    %__MODULE__{
      inverse_bind_matrices: Map.get(json, "inverseBindMatrices"),
      skeleton: Map.get(json, "skeleton"),
      joints: Map.get(json, "joints", []),
      name: Map.get(json, "name")
    }
  end

  @doc """
  Convert skin to JSON representation.
  """
  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = skin) do
    %{}
    |> maybe_put("inverseBindMatrices", skin.inverse_bind_matrices)
    |> maybe_put("skeleton", skin.skeleton)
    |> maybe_put("joints", skin.joints)
    |> maybe_put("name", skin.name)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
