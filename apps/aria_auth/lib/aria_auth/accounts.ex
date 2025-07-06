# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaAuth.Accounts do
  @moduledoc "The Accounts context for managing users.\n"
  import Ecto.Query, warn: false
  alias AriaAuth.Repo
  alias AriaAuth.Accounts.User
  @doc "Returns the list of users.\n"
  def list_users do
    Repo.all(User)
  end

  @doc "Gets a single user.\n"
  def get_user!(id) do
    Repo.get!(User, id)
  end

  @doc "Gets a single user.\n"
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc "Gets a user by email.\n"
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc "Gets a user by provider and provider uid.\n"
  def get_user_by_provider(provider, provider_uid) do
    Repo.get_by(User, provider: provider, provider_uid: provider_uid)
  end

  @doc "Creates a user.\n"
  def create_user(attrs \\ %{}) do
    %User{} |> User.registration_changeset(attrs) |> Repo.insert()
  end

  @doc "Updates a user.\n"
  def update_user(%User{} = user, attrs) do
    user |> User.changeset(attrs) |> Repo.update()
  end

  @doc "Updates a user's password.\n"
  def update_user_password(%User{} = user, password) do
    user |> User.password_changeset(%{password: password}) |> Repo.update()
  end

  @doc "Deletes a user.\n"
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc "Returns an `%Ecto.Changeset{}` for tracking user changes.\n"
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc "Authenticates a user with email and password.\n"
  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    case get_user_by_email(email) do
      nil ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          update_sign_in_tracking(user)
          {:ok, user}
        else
          update_failed_attempts(user)
          {:error, :invalid_credentials}
        end
    end
  end

  @doc "Confirms a user's email address.\n"
  def confirm_user_email(%User{} = user) do
    user
    |> User.changeset(%{email_verified_at: DateTime.utc_now(), confirmation_token: nil})
    |> Repo.update()
  end

  @doc "Locks a user account.\n"
  def lock_user(%User{} = user) do
    user |> User.changeset(%{locked_at: DateTime.utc_now()}) |> Repo.update()
  end

  @doc "Unlocks a user account.\n"
  def unlock_user(%User{} = user) do
    user
    |> User.changeset(%{locked_at: nil, failed_attempts: 0, unlock_token: nil})
    |> Repo.update()
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
    |> Repo.update()
  end

  defp update_failed_attempts(%User{} = user) do
    failed_attempts = (user.failed_attempts || 0) + 1
    max_attempts = Application.get_env(:aria_auth, :max_failed_attempts, 5)
    changes = %{failed_attempts: failed_attempts}

    changes =
      if failed_attempts >= max_attempts do
        Map.put(changes, :locked_at, DateTime.utc_now())
      else
        changes
      end

    user |> User.changeset(changes) |> Repo.update()
  end
end
