# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaAuth.Macaroons.ConfineUserString do
  @moduledoc """
  Custom caveat for confining macaroons to specific string user IDs (UUIDs).
  Similar to Macfly.Caveat.ConfineUser but accepts string IDs instead of integers.
  """

  @derive Jason.Encoder
  defstruct [:id]

  @type t :: %__MODULE__{id: String.t()}

  def build(user_id) when is_binary(user_id) do
    %__MODULE__{id: user_id}
  end
end

defimpl Macfly.Caveat, for: AriaAuth.Macaroons.ConfineUserString do
  def name(_) do
    "ConfineUserString"
  end

  def type(_) do
    101
  end

  def body(%AriaAuth.Macaroons.ConfineUserString{id: id}) do
    [id]
  end

  def from_body(_, [id], _) when is_binary(id) do
    {:ok, %AriaAuth.Macaroons.ConfineUserString{id: id}}
  end

  def from_body(_, _, _) do
    {:error, "bad ConfineUserString format"}
  end
end
