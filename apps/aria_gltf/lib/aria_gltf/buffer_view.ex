defmodule AriaGltf.BufferView do
  @moduledoc """
  A view into a buffer generally representing a subset of the buffer.

  From glTF 2.0 specification section 5.11:
  A buffer view represents a contiguous segment of data in a buffer, defined by a byte offset into the
  buffer specified in the byteOffset property and a total byte length specified by the byteLength
  property of the buffer view.
  """

  @type target :: :array_buffer | :element_array_buffer

  @type t :: %__MODULE__{
          buffer: non_neg_integer(),
          byte_offset: non_neg_integer(),
          byte_length: non_neg_integer(),
          byte_stride: non_neg_integer() | nil,
          target: target() | nil,
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @enforce_keys [:buffer, :byte_length]
  defstruct [
    :buffer,
    :byte_offset,
    :byte_length,
    :byte_stride,
    :target,
    :name,
    :extensions,
    :extras
  ]

  # WebGL constants for target
  @array_buffer 34962
  @element_array_buffer 34963

  @doc """
  Creates a new BufferView struct.

  ## Parameters
  - `buffer`: The index of the buffer (required)
  - `byte_length`: The length of the bufferView in bytes (required)
  - `byte_offset`: The offset into the buffer in bytes (optional, default: 0)
  - `byte_stride`: The stride, in bytes (optional)
  - `target`: The hint representing the intended GPU buffer type (optional)
  - `name`: The user-defined name of this object (optional)
  - `extensions`: JSON object with extension-specific objects (optional)
  - `extras`: Application-specific data (optional)

  ## Examples

      iex> AriaGltf.BufferView.new(0, 1024)
      %AriaGltf.BufferView{buffer: 0, byte_length: 1024, byte_offset: 0, byte_stride: nil, target: nil, name: nil, extensions: nil, extras: nil}

      iex> AriaGltf.BufferView.new(0, 512, byte_offset: 256, target: :array_buffer)
      %AriaGltf.BufferView{buffer: 0, byte_length: 512, byte_offset: 256, byte_stride: nil, target: :array_buffer, name: nil, extensions: nil, extras: nil}
  """
  @spec new(non_neg_integer(), non_neg_integer(), keyword()) :: t()
  def new(buffer, byte_length, opts \\ []) when is_integer(buffer) and buffer >= 0 and is_integer(byte_length) and byte_length >= 1 do
    %__MODULE__{
      buffer: buffer,
      byte_length: byte_length,
      byte_offset: Keyword.get(opts, :byte_offset, 0),
      byte_stride: Keyword.get(opts, :byte_stride),
      target: Keyword.get(opts, :target),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Validates a BufferView struct according to glTF 2.0 specification.

  ## Validation Rules
  - buffer must be >= 0
  - byte_length must be >= 1
  - byte_offset must be >= 0
  - byte_stride must be >= 4 and <= 252 and multiple of 4 if present
  - target must be valid WebGL enum if present

  ## Examples

      iex> buffer_view = AriaGltf.BufferView.new(0, 1024)
      iex> AriaGltf.BufferView.validate(buffer_view)
      :ok

      iex> invalid_buffer_view = %AriaGltf.BufferView{buffer: 0, byte_length: 0, byte_offset: 0}
      iex> AriaGltf.BufferView.validate(invalid_buffer_view)
      {:error, "byte_length must be >= 1"}
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = buffer_view) do
    with :ok <- validate_buffer(buffer_view.buffer),
         :ok <- validate_byte_length(buffer_view.byte_length),
         :ok <- validate_byte_offset(buffer_view.byte_offset),
         :ok <- validate_byte_stride(buffer_view.byte_stride),
         :ok <- validate_target(buffer_view.target) do
      :ok
    end
  end

  defp validate_buffer(buffer) when is_integer(buffer) and buffer >= 0, do: :ok
  defp validate_buffer(_), do: {:error, "buffer must be >= 0"}

  defp validate_byte_length(byte_length) when is_integer(byte_length) and byte_length >= 1, do: :ok
  defp validate_byte_length(_), do: {:error, "byte_length must be >= 1"}

  defp validate_byte_offset(byte_offset) when is_integer(byte_offset) and byte_offset >= 0, do: :ok
  defp validate_byte_offset(_), do: {:error, "byte_offset must be >= 0"}

  defp validate_byte_stride(nil), do: :ok
  defp validate_byte_stride(byte_stride) when is_integer(byte_stride) and byte_stride >= 4 and byte_stride <= 252 and rem(byte_stride, 4) == 0, do: :ok
  defp validate_byte_stride(_), do: {:error, "byte_stride must be >= 4, <= 252, and multiple of 4"}

  defp validate_target(nil), do: :ok
  defp validate_target(target) when target in [:array_buffer, :element_array_buffer], do: :ok
  defp validate_target(_), do: {:error, "target must be :array_buffer or :element_array_buffer"}

  @doc """
  Converts a BufferView struct to a map suitable for JSON encoding.

  ## Examples

      iex> buffer_view = AriaGltf.BufferView.new(0, 1024, byte_offset: 256, target: :array_buffer)
      iex> AriaGltf.BufferView.to_map(buffer_view)
      %{
        "buffer" => 0,
        "byteLength" => 1024,
        "byteOffset" => 256,
        "target" => 34962
      }
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = buffer_view) do
    %{}
    |> put_if_present("buffer", buffer_view.buffer)
    |> put_if_present("byteLength", buffer_view.byte_length)
    |> put_if_present("byteOffset", buffer_view.byte_offset, 0)
    |> put_if_present("byteStride", buffer_view.byte_stride)
    |> put_if_present("target", target_to_int(buffer_view.target))
    |> put_if_present("name", buffer_view.name)
    |> put_if_present("extensions", buffer_view.extensions)
    |> put_if_present("extras", buffer_view.extras)
  end

  @doc """
  Creates a BufferView struct from a map (typically from JSON parsing).

  ## Examples

      iex> map = %{"buffer" => 0, "byteLength" => 1024, "byteOffset" => 256}
      iex> AriaGltf.BufferView.from_map(map)
      {:ok, %AriaGltf.BufferView{buffer: 0, byte_length: 1024, byte_offset: 256, byte_stride: nil, target: nil, name: nil, extensions: nil, extras: nil}}

      iex> invalid_map = %{"buffer" => 0}
      iex> AriaGltf.BufferView.from_map(invalid_map)
      {:error, "Missing required field: byteLength"}
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, String.t()}
  def from_map(map) when is_map(map) do
    with {:ok, buffer} <- get_required_field(map, "buffer"),
         {:ok, byte_length} <- get_required_field(map, "byteLength") do
      buffer_view = %__MODULE__{
        buffer: buffer,
        byte_length: byte_length,
        byte_offset: Map.get(map, "byteOffset", 0),
        byte_stride: Map.get(map, "byteStride"),
        target: int_to_target(Map.get(map, "target")),
        name: Map.get(map, "name"),
        extensions: Map.get(map, "extensions"),
        extras: Map.get(map, "extras")
      }

      case validate(buffer_view) do
        :ok -> {:ok, buffer_view}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Checks if this buffer view is used for vertex attributes.

  Buffer views with target :array_buffer are typically used for vertex attributes.

  ## Examples

      iex> buffer_view = AriaGltf.BufferView.new(0, 1024, target: :array_buffer)
      iex> AriaGltf.BufferView.vertex_attributes?(buffer_view)
      true

      iex> buffer_view = AriaGltf.BufferView.new(0, 1024, target: :element_array_buffer)
      iex> AriaGltf.BufferView.vertex_attributes?(buffer_view)
      false
  """
  @spec vertex_attributes?(t()) :: boolean()
  def vertex_attributes?(%__MODULE__{target: :array_buffer}), do: true
  def vertex_attributes?(%__MODULE__{}), do: false

  @doc """
  Checks if this buffer view is used for vertex indices.

  Buffer views with target :element_array_buffer are used for vertex indices.

  ## Examples

      iex> buffer_view = AriaGltf.BufferView.new(0, 1024, target: :element_array_buffer)
      iex> AriaGltf.BufferView.vertex_indices?(buffer_view)
      true

      iex> buffer_view = AriaGltf.BufferView.new(0, 1024, target: :array_buffer)
      iex> AriaGltf.BufferView.vertex_indices?(buffer_view)
      false
  """
  @spec vertex_indices?(t()) :: boolean()
  def vertex_indices?(%__MODULE__{target: :element_array_buffer}), do: true
  def vertex_indices?(%__MODULE__{}), do: false

  # Helper functions

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp put_if_present(map, _key, value, default) when value == default, do: map
  defp put_if_present(map, key, value, _default), do: Map.put(map, key, value)

  defp get_required_field(map, key) do
    case Map.get(map, key) do
      nil -> {:error, "Missing required field: #{key}"}
      value -> {:ok, value}
    end
  end

  defp target_to_int(:array_buffer), do: @array_buffer
  defp target_to_int(:element_array_buffer), do: @element_array_buffer
  defp target_to_int(nil), do: nil

  defp int_to_target(@array_buffer), do: :array_buffer
  defp int_to_target(@element_array_buffer), do: :element_array_buffer
  defp int_to_target(nil), do: nil
  defp int_to_target(_), do: nil
end
