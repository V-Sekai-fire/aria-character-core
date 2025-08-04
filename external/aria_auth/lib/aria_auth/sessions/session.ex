# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaAuth.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset
  alias AriaAuth.Accounts.User

  schema("sessions") do
    field(:token, :string)
    field(:refresh_token, :string)
    field(:expires_at, :utc_datetime)
    field(:last_activity_at, :utc_datetime)
    belongs_to(:user, User)
    timestamps()
  end

  @doc "A session changeset for creation.\n"
  def create_changeset(session, user, attrs) do
    session
    |> cast(attrs, [:token, :refresh_token, :expires_at, :last_activity_at])
    |> validate_required([:token, :refresh_token, :expires_at, :last_activity_at])
    |> put_assoc(:user, user)
  end

  @doc "A session changeset for updates.\n"
  def changeset(session, attrs) do
    session |> cast(attrs, [:token, :refresh_token, :expires_at, :last_activity_at])
  end

  @doc "Checks if a session is active.\n"
  def active?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end
end
