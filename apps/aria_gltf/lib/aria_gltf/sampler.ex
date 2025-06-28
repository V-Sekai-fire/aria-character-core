# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf.Sampler do
  @moduledoc """
  Mock implementation of AriaGltf.Sampler for compilation.

  This module represents glTF texture sampling parameters.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: %__MODULE__{
    mag_filter: non_neg_integer() | nil,
    min_filter: non_neg_integer() | nil,
    wrap_s: non_neg_integer() | nil,
    wrap_t: non_neg_integer() | nil,
    name: String.t() | nil
  }

  defstruct [:mag_filter, :min_filter, :wrap_s, :wrap_t, :name]

  @doc """
  Create a new sampler from JSON data.
  """
  @spec from_json(map()) :: t()
  def from_json(json) when is_map(json) do
    %__MODULE__{
      mag_filter: Map.get(json, "magFilter"),
      min_filter: Map.get(json, "minFilter"),
      wrap_s: Map.get(json, "wrapS"),
      wrap_t: Map.get(json, "wrapT"),
      name: Map.get(json, "name")
    }
  end

  @doc """
  Convert sampler to JSON representation.
  """
  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = sampler) do
    %{}
    |> maybe_put("magFilter", sampler.mag_filter)
    |> maybe_put("minFilter", sampler.min_filter)
    |> maybe_put("wrapS", sampler.wrap_s)
    |> maybe_put("wrapT", sampler.wrap_t)
    |> maybe_put("name", sampler.name)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
