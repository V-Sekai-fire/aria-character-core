# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf.Material.OcclusionTextureInfo do
  @moduledoc """
  Reference to a texture with occlusion texture specific properties.
  """

  @type t :: %__MODULE__{
          index: non_neg_integer(),
          tex_coord: non_neg_integer(),
          strength: float(),
          extensions: map() | nil,
          extras: any() | nil
        }

  defstruct [
    :index,
    :extensions,
    :extras,
    tex_coord: 0,
    strength: 1.0
  ]

  @doc """
  Creates a new OcclusionTextureInfo struct.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      index: Keyword.fetch!(opts, :index),
      tex_coord: Keyword.get(opts, :tex_coord, 0),
      strength: Keyword.get(opts, :strength, 1.0),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Validates an OcclusionTextureInfo struct.
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = texture_info) do
    with :ok <- validate_index(texture_info.index),
         :ok <- validate_tex_coord(texture_info.tex_coord),
         :ok <- validate_strength(texture_info.strength) do
      :ok
    end
  end

  @doc """
  Converts an OcclusionTextureInfo struct to a map.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = texture_info) do
    %{}
    |> put_if_present("index", texture_info.index)
    |> put_if_present("texCoord", texture_info.tex_coord, 0)
    |> put_if_present("strength", texture_info.strength, 1.0)
    |> put_if_present("extensions", texture_info.extensions)
    |> put_if_present("extras", texture_info.extras)
  end

  @doc """
  Creates an OcclusionTextureInfo struct from a map.
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, String.t()}
  def from_map(map) when is_map(map) do
    case Map.get(map, "index") do
      nil ->
        {:error, "index is required"}

      index when is_integer(index) and index >= 0 ->
        texture_info = %__MODULE__{
          index: index,
          tex_coord: Map.get(map, "texCoord", 0),
          strength: Map.get(map, "strength", 1.0),
          extensions: Map.get(map, "extensions"),
          extras: Map.get(map, "extras")
        }

        case validate(texture_info) do
          :ok -> {:ok, texture_info}
          {:error, reason} -> {:error, reason}
        end

      _ ->
        {:error, "index must be a non-negative integer"}
    end
  end

  # Private validation functions

  defp validate_index(index) when is_integer(index) and index >= 0, do: :ok
  defp validate_index(_), do: {:error, "index must be a non-negative integer"}

  defp validate_tex_coord(tex_coord) when is_integer(tex_coord) and tex_coord >= 0, do: :ok
  defp validate_tex_coord(_), do: {:error, "tex_coord must be a non-negative integer"}

  defp validate_strength(strength) when is_number(strength) and strength >= 0.0 and strength <= 1.0, do: :ok
  defp validate_strength(_), do: {:error, "strength must be a number between 0.0 and 1.0"}

  # Helper functions

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, _key, value, default) when value == default, do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
  defp put_if_present(map, key, value, _default), do: Map.put(map, key, value)
end
