# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.Accounts do
  @moduledoc """
  The Accounts context for managing users.
  """

  import Ecto.Query, warn: false
  alias AriaData.AuthRepo
  alias AriaAuth.Accounts.User

  @doc """
  Returns the list of users.
  """
  def list_users do
    AuthRepo.all(User)
  end

  @doc """
  Gets a single user.
  """
  def get_user!(id), do: AuthRepo.get!(User, id)

  @doc """
  Gets a single user.
  """
  def get_user(id), do: AuthRepo.get(User, id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    AuthRepo.get_by(User, email: email)
  end

  @doc """
  Gets a user by provider and provider uid.
  """
  def get_user_by_provider(provider, provider_uid) do
    AuthRepo.get_by(User, provider: provider, provider_uid: provider_uid)
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> AuthRepo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> AuthRepo.update()
  end

  @doc """
  Updates a user's password.
  """
  def update_user_password(%User{} = user, password) do
    user
    |> User.password_changeset(%{password: password})
    |> AuthRepo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    AuthRepo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Authenticates a user with email and password.
  """
  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    case get_user_by_email(email) do
      nil ->
        # Run password hashing to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          # Update sign in tracking
          update_sign_in_tracking(user)
          {:ok, user}
        else
          update_failed_attempts(user)
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Confirms a user's email address.
  """
  def confirm_user_email(%User{} = user) do
    user
    |> User.changeset(%{email_verified_at: DateTime.utc_now(), confirmation_token: nil})
    |> AuthRepo.update()
  end

  @doc """
  Locks a user account.
  """
  def lock_user(%User{} = user) do
    user
    |> User.changeset(%{locked_at: DateTime.utc_now()})
    |> AuthRepo.update()
  end

  @doc """
  Unlocks a user account.
  """
  def unlock_user(%User{} = user) do
    user
    |> User.changeset(%{locked_at: nil, failed_attempts: 0, unlock_token: nil})
    |> AuthRepo.update()
  end

  defp update_sign_in_tracking(%User{} = user) do
    current_time = DateTime.utc_now()
    
    user
    |> User.changeset(%{
      last_sign_in_at: user.current_sign_in_at,
      current_sign_in_at: current_time,
      sign_in_count: (user.sign_in_count || 0) + 1,
      failed_attempts: 0
    })
    |> AuthRepo.update()
  end

  defp update_failed_attempts(%User{} = user) do
    failed_attempts = (user.failed_attempts || 0) + 1
    max_attempts = Application.get_env(:aria_auth, :max_failed_attempts, 5)

    changes = %{failed_attempts: failed_attempts}
    changes = if failed_attempts >= max_attempts do
      Map.put(changes, :locked_at, DateTime.utc_now())
    else
      changes
    end

    user
    |> User.changeset(changes)
    |> AuthRepo.update()
  end
end
