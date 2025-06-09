# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.Accounts.User do
  @moduledoc """
  User schema for authentication and account management.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :first_name, :string
    field :last_name, :string
    field :display_name, :string
    field :avatar_url, :string
    field :email_verified_at, :utc_datetime
    field :locked_at, :utc_datetime
    field :last_sign_in_at, :utc_datetime
    field :current_sign_in_at, :utc_datetime
    field :sign_in_count, :integer, default: 0
    field :failed_attempts, :integer, default: 0
    field :unlock_token, :string
    field :confirmation_token, :string
    field :reset_password_token, :string
    field :reset_password_sent_at, :utc_datetime
    field :provider, :string
    field :provider_uid, :string
    field :provider_data, :map
    field :roles, {:array, :string}, default: ["user"]
    field :preferences, :map, default: %{}
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email, :password, :first_name, :last_name, :display_name, :avatar_url,
      :provider, :provider_uid, :provider_data, :roles, :preferences, :metadata
    ])
    |> validate_required([:email])
    |> validate_email()
    |> validate_password()
    |> unique_constraint(:email)
    |> unique_constraint([:provider, :provider_uid])
    |> put_password_hash()
  end

  @doc false
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name, :display_name])
    |> validate_required([:email, :password])
    |> validate_email()
    |> validate_password()
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  @doc false
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> put_password_hash()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 160)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "must contain at least one lowercase letter")
    |> validate_format(:password, ~r/[A-Z]/, message: "must contain at least one uppercase letter")
    |> validate_format(:password, ~r/[0-9]/, message: "must contain at least one number")
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
