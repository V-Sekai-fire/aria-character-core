# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaGltf.Camera do
  @moduledoc """
  Implementation of AriaGltf.Camera for glTF 2.0 specification compliance.

  This module represents glTF camera definitions supporting both perspective
  and orthographic camera types with full specification compliance.

  ## glTF 2.0 Camera Specification

  A camera defines a viewing transformation used for rendering. There are two
  camera types: perspective and orthographic.

  ### Perspective Camera

  A perspective camera contains properties to create a perspective projection matrix.

  - `yfov` (required): Vertical field of view in radians
  - `znear` (required): Distance to near clipping plane
  - `aspectRatio` (optional): Aspect ratio of the field of view
  - `zfar` (optional): Distance to far clipping plane

  ### Orthographic Camera

  An orthographic camera contains properties to create an orthographic projection matrix.

  - `xmag` (required): Horizontal magnification
  - `ymag` (required): Vertical magnification
  - `zfar` (required): Distance to far clipping plane
  - `znear` (required): Distance to near clipping plane

  ## Examples

      # Create perspective camera
      perspective = AriaGltf.Camera.new_perspective(
        yfov: :math.pi / 3,
        znear: 0.1,
        aspect_ratio: 16.0 / 9.0,
        zfar: 1000.0
      )

      # Create orthographic camera
      orthographic = AriaGltf.Camera.new_orthographic(
        xmag: 10.0,
        ymag: 10.0,
        znear: 0.1,
        zfar: 1000.0
      )
  """

  defmodule Orthographic do
    @moduledoc """
    Orthographic projection camera properties.
    """

    @type t :: %__MODULE__{
            xmag: float(),
            ymag: float(),
            zfar: float(),
            znear: float(),
            extensions: map() | nil,
            extras: any() | nil
          }

    defstruct [
      :xmag,
      :ymag,
      :zfar,
      :znear,
      :extensions,
      :extras
    ]
  end

  defmodule Perspective do
    @moduledoc """
    Perspective projection camera properties.
    """

    @type t :: %__MODULE__{
            aspect_ratio: float() | nil,
            yfov: float(),
            zfar: float() | nil,
            znear: float(),
            extensions: map() | nil,
            extras: any() | nil
          }

    defstruct [
      :aspect_ratio,
      :yfov,
      :zfar,
      :znear,
      :extensions,
      :extras
    ]
  end

  # Perspective camera properties
  @type perspective :: %{
    yfov: float(),
    znear: float(),
    aspect_ratio: float() | nil,
    zfar: float() | nil
  }

  # Orthographic camera properties
  @type orthographic :: %{
    xmag: float(),
    ymag: float(),
    zfar: float(),
    znear: float()
  }

  @type camera_type :: :perspective | :orthographic

  @type t :: %__MODULE__{
    type: camera_type(),
    perspective: perspective() | nil,
    orthographic: orthographic() | nil,
    name: String.t() | nil,
    extensions: map() | nil,
    extras: any() | nil
  }

  defstruct [:type, :perspective, :orthographic, :name, :extensions, :extras]

  @doc """
  Creates a new perspective camera.

  ## Parameters

  - `yfov`: Vertical field of view in radians (required)
  - `znear`: Distance to near clipping plane (required)
  - `aspect_ratio`: Aspect ratio of the field of view (optional)
  - `zfar`: Distance to far clipping plane (optional)
  - `name`: Camera name (optional)

  ## Examples

      camera = AriaGltf.Camera.new_perspective(
        yfov: :math.pi / 4,
        znear: 0.1,
        aspect_ratio: 16.0 / 9.0,
        zfar: 1000.0,
        name: "MainCamera"
      )

  ## Validation

  - `yfov` must be > 0 and < π
  - `znear` must be > 0
  - `zfar` must be > `znear` (if provided)
  - `aspect_ratio` must be > 0 (if provided)
  """
  @spec new_perspective(keyword()) :: {:ok, t()} | {:error, term()}
  def new_perspective(options) do
    with {:ok, yfov} <- validate_yfov(Keyword.get(options, :yfov)),
         {:ok, znear} <- validate_znear(Keyword.get(options, :znear)),
         {:ok, aspect_ratio} <- validate_aspect_ratio(Keyword.get(options, :aspect_ratio)),
         {:ok, zfar} <- validate_zfar(Keyword.get(options, :zfar), znear) do

      perspective = %{
        yfov: yfov,
        znear: znear,
        aspect_ratio: aspect_ratio,
        zfar: zfar
      }

      camera = %__MODULE__{
        type: :perspective,
        perspective: perspective,
        name: Keyword.get(options, :name)
      }

      {:ok, camera}
    end
  end

  @doc """
  Creates a new orthographic camera.

  ## Parameters

  - `xmag`: Horizontal magnification (required)
  - `ymag`: Vertical magnification (required)
  - `zfar`: Distance to far clipping plane (required)
  - `znear`: Distance to near clipping plane (required)
  - `name`: Camera name (optional)

  ## Examples

      camera = AriaGltf.Camera.new_orthographic(
        xmag: 10.0,
        ymag: 10.0,
        zfar: 1000.0,
        znear: 0.1,
        name: "OrthoCamera"
      )

  ## Validation

  - `xmag` must be > 0
  - `ymag` must be > 0
  - `znear` must be > 0
  - `zfar` must be > `znear`
  """
  @spec new_orthographic(keyword()) :: {:ok, t()} | {:error, term()}
  def new_orthographic(options) do
    with {:ok, xmag} <- validate_mag(Keyword.get(options, :xmag), :xmag),
         {:ok, ymag} <- validate_mag(Keyword.get(options, :ymag), :ymag),
         {:ok, znear} <- validate_znear(Keyword.get(options, :znear)),
         {:ok, zfar} <- validate_zfar_required(Keyword.get(options, :zfar), znear) do

      orthographic = %{
        xmag: xmag,
        ymag: ymag,
        zfar: zfar,
        znear: znear
      }

      camera = %__MODULE__{
        type: :orthographic,
        orthographic: orthographic,
        name: Keyword.get(options, :name)
      }

      {:ok, camera}
    end
  end

  @doc """
  Creates a new camera with type, properties, and options (legacy API).

  This function provides backward compatibility with the previous API.
  For new code, prefer `new_perspective/1` or `new_orthographic/1`.
  """
  @spec new(String.t(), map(), map()) :: {:ok, t()} | {:error, term()}
  def new(type, properties, options \\ %{}) when is_binary(type) and is_map(properties) do
    name = Map.get(options, :name)

    case type do
      "perspective" ->
        options = [
          yfov: Map.get(properties, :yfov),
          znear: Map.get(properties, :znear),
          aspect_ratio: Map.get(properties, :aspect_ratio),
          zfar: Map.get(properties, :zfar),
          name: name
        ]
        new_perspective(options)

      "orthographic" ->
        options = [
          xmag: Map.get(properties, :xmag),
          ymag: Map.get(properties, :ymag),
          zfar: Map.get(properties, :zfar),
          znear: Map.get(properties, :znear),
          name: name
        ]
        new_orthographic(options)

      _ ->
        {:error, {:invalid_camera_type, type}}
    end
  end

  @doc """
  Create a new camera from JSON data.

  Parses glTF JSON representation into a Camera struct with full validation.

  ## Examples

      json = %{
        "type" => "perspective",
        "perspective" => %{
          "yfov" => 0.785398,
          "znear" => 0.1,
          "aspectRatio" => 1.777778,
          "zfar" => 1000.0
        },
        "name" => "Camera"
      }

      {:ok, camera} = AriaGltf.Camera.from_json(json)
  """
  @spec from_json(map()) :: {:ok, t()} | {:error, term()}
  def from_json(json) when is_map(json) do
    type = Map.get(json, "type")
    name = Map.get(json, "name")

    case type do
      "perspective" ->
        case Map.get(json, "perspective") do
          nil ->
            {:error, {:missing_required_field, "perspective"}}

          perspective_data ->
            options = [
              yfov: Map.get(perspective_data, "yfov"),
              znear: Map.get(perspective_data, "znear"),
              aspect_ratio: Map.get(perspective_data, "aspectRatio"),
              zfar: Map.get(perspective_data, "zfar"),
              name: name
            ]
            new_perspective(options)
        end

      "orthographic" ->
        case Map.get(json, "orthographic") do
          nil ->
            {:error, {:missing_required_field, "orthographic"}}

          orthographic_data ->
            options = [
              xmag: Map.get(orthographic_data, "xmag"),
              ymag: Map.get(orthographic_data, "ymag"),
              zfar: Map.get(orthographic_data, "zfar"),
              znear: Map.get(orthographic_data, "znear"),
              name: name
            ]
            new_orthographic(options)
        end

      nil ->
        {:error, {:missing_required_field, "type"}}

      _ ->
        {:error, {:invalid_camera_type, type}}
    end
  end

  @doc """
  Convert camera to JSON representation.

  Generates glTF-compliant JSON representation of the camera.

  ## Examples

      json = AriaGltf.Camera.to_json(camera)
      # Returns: %{
      #   "type" => "perspective",
      #   "perspective" => %{
      #     "yfov" => 0.785398,
      #     "znear" => 0.1,
      #     "aspectRatio" => 1.777778,
      #     "zfar" => 1000.0
      #   },
      #   "name" => "Camera"
      # }
  """
  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{type: :perspective, perspective: perspective} = camera) do
    perspective_json = %{}
    |> Map.put("yfov", perspective.yfov)
    |> Map.put("znear", perspective.znear)
    |> maybe_put("aspectRatio", perspective.aspect_ratio)
    |> maybe_put("zfar", perspective.zfar)

    %{}
    |> Map.put("type", "perspective")
    |> Map.put("perspective", perspective_json)
    |> maybe_put("name", camera.name)
  end

  def to_json(%__MODULE__{type: :orthographic, orthographic: orthographic} = camera) do
    orthographic_json = %{}
    |> Map.put("xmag", orthographic.xmag)
    |> Map.put("ymag", orthographic.ymag)
    |> Map.put("zfar", orthographic.zfar)
    |> Map.put("znear", orthographic.znear)

    %{}
    |> Map.put("type", "orthographic")
    |> Map.put("orthographic", orthographic_json)
    |> maybe_put("name", camera.name)
  end

  @doc """
  Validate a camera struct for glTF 2.0 compliance.

  ## Examples

      case AriaGltf.Camera.validate(camera) do
        :ok -> # camera is valid
        {:error, reason} -> # camera is invalid
      end
  """
  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{type: :perspective, perspective: perspective}) do
    with :ok <- validate_yfov(perspective.yfov),
         :ok <- validate_znear(perspective.znear),
         :ok <- validate_aspect_ratio(perspective.aspect_ratio),
         :ok <- validate_zfar(perspective.zfar, perspective.znear) do
      :ok
    end
  end

  def validate(%__MODULE__{type: :orthographic, orthographic: orthographic}) do
    with :ok <- validate_mag(orthographic.xmag, :xmag),
         :ok <- validate_mag(orthographic.ymag, :ymag),
         :ok <- validate_znear(orthographic.znear),
         :ok <- validate_zfar_required(orthographic.zfar, orthographic.znear) do
      :ok
    end
  end

  def validate(_), do: {:error, :invalid_camera_struct}

  # Private validation functions

  defp validate_yfov(nil), do: {:error, {:missing_required_field, :yfov}}
  defp validate_yfov(yfov) when is_number(yfov) do
    if yfov > 0 and yfov < :math.pi() do
      {:ok, yfov}
    else
      {:error, {:invalid_yfov, yfov, "must be > 0 and < π"}}
    end
  end
  defp validate_yfov(yfov), do: {:error, {:invalid_yfov, yfov, "must be > 0 and < π"}}

  defp validate_znear(nil), do: {:error, {:missing_required_field, :znear}}
  defp validate_znear(znear) when is_number(znear) and znear > 0, do: {:ok, znear}
  defp validate_znear(znear), do: {:error, {:invalid_znear, znear, "must be > 0"}}

  defp validate_aspect_ratio(nil), do: {:ok, nil}
  defp validate_aspect_ratio(ratio) when is_number(ratio) and ratio > 0, do: {:ok, ratio}
  defp validate_aspect_ratio(ratio), do: {:error, {:invalid_aspect_ratio, ratio, "must be > 0"}}

  defp validate_zfar(nil, _znear), do: {:ok, nil}
  defp validate_zfar(zfar, znear) when is_number(zfar) and is_number(znear) and zfar > znear, do: {:ok, zfar}
  defp validate_zfar(zfar, znear), do: {:error, {:invalid_zfar, zfar, "must be > znear (#{znear})"}}

  defp validate_zfar_required(nil, _znear), do: {:error, {:missing_required_field, :zfar}}
  defp validate_zfar_required(zfar, znear) when is_number(zfar) and is_number(znear) and zfar > znear, do: {:ok, zfar}
  defp validate_zfar_required(zfar, znear), do: {:error, {:invalid_zfar, zfar, "must be > znear (#{znear})"}}

  defp validate_mag(nil, field), do: {:error, {:missing_required_field, field}}
  defp validate_mag(mag, _field) when is_number(mag) and mag > 0, do: {:ok, mag}
  defp validate_mag(mag, field), do: {:error, {:invalid_magnification, field, mag, "must be > 0"}}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
