# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaAuth.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema("users") do
    field(:email, :string)
    field(:password_hash, :string)
    field(:email_verified_at, :utc_datetime)
    field(:confirmation_token, :string)
    field(:reset_password_token, :string)
    field(:reset_password_sent_at, :utc_datetime)
    field(:locked_at, :utc_datetime)
    field(:failed_attempts, :integer, default: 0)
    field(:unlock_token, :string)
    field(:provider, :string)
    field(:provider_uid, :string)
    field(:sign_in_count, :integer, default: 0)
    field(:current_sign_in_at, :utc_datetime)
    field(:last_sign_in_at, :utc_datetime)
    field(:roles, {:array, :string}, default: [])
    timestamps()
  end

  @doc "A user changeset for registration.\n"
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password_hash, :provider, :provider_uid, :roles])
    |> validate_required([:email, :password_hash])
    |> unique_constraint(:email)
  end

  @doc "A user changeset for updating user information.\n"
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :email_verified_at,
      :confirmation_token,
      :reset_password_token,
      :reset_password_sent_at,
      :locked_at,
      :failed_attempts,
      :unlock_token,
      :provider,
      :provider_uid,
      :sign_in_count,
      :current_sign_in_at,
      :last_sign_in_at,
      :roles
    ])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end

  @doc "A user changeset for updating password.\n"
  def password_changeset(user, attrs) do
    user |> cast(attrs, [:password_hash]) |> validate_required([:password_hash])
  end
end
