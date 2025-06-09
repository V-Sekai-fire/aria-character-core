# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.Sessions.Session do
  @moduledoc """
  Session schema for managing user sessions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "sessions" do
    field :token, :string
    field :refresh_token, :string
    field :user_agent, :string
    field :ip_address, :string
    field :expires_at, :utc_datetime
    field :last_activity_at, :utc_datetime
    field :metadata, :map, default: %{}
    
    belongs_to :user, AriaAuth.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:token, :refresh_token, :user_agent, :ip_address, :expires_at, :last_activity_at, :metadata, :user_id])
    |> validate_required([:token, :user_id, :expires_at])
    |> unique_constraint(:token)
    |> foreign_key_constraint(:user_id)
  end

  @doc false
  def create_changeset(session, user, attrs \\ %{}) do
    expires_at = DateTime.add(DateTime.utc_now(), Application.get_env(:aria_auth, :session_ttl, 3600), :second)
    token = generate_session_token()
    refresh_token = generate_session_token()

    session
    |> cast(attrs, [:user_agent, :ip_address, :metadata])
    |> put_change(:user_id, user.id)
    |> put_change(:token, token)
    |> put_change(:refresh_token, refresh_token)
    |> put_change(:expires_at, expires_at)
    |> put_change(:last_activity_at, DateTime.utc_now())
    |> validate_required([:token, :user_id, :expires_at])
  end

  defp generate_session_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  def active?(%__MODULE__{} = session) do
    not expired?(session)
  end
end
