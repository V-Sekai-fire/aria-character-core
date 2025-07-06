# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaAuth.Macaroons.PermissionsCaveat do
  @moduledoc """
  Custom caveat for encoding user permissions/roles in macaroons.
  """

  @derive Jason.Encoder
  defstruct [:permissions]

  @type t :: %__MODULE__{permissions: [String.t()]}

  def build(permissions) when is_list(permissions) do
    %__MODULE__{permissions: permissions}
  end
end

defimpl Macfly.Caveat, for: AriaAuth.Macaroons.PermissionsCaveat do
  def name(_) do
    "PermissionsCaveat"
  end

  def type(_) do
    100
  end

  def body(%AriaAuth.Macaroons.PermissionsCaveat{permissions: permissions}) do
    [permissions]
  end

  def from_body(_, [permissions], _) when is_list(permissions) do
    {:ok, %AriaAuth.Macaroons.PermissionsCaveat{permissions: permissions}}
  end

  def from_body(_, _, _) do
    {:error, "bad PermissionsCaveat format"}
  end
end
