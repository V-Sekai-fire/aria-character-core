# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaAuth.Sessions do
  @moduledoc "The Sessions context for managing user sessions.\n"
  import Ecto.Query, warn: false
  alias AriaAuth.Repo
  alias AriaAuth.Sessions.Session
  alias AriaAuth.Accounts.User
  @doc "Creates a session for a user.\n"
  def create_session(%User{} = user, attrs \\ %{}) do
    %Session{} |> Session.create_changeset(user, attrs) |> Repo.insert()
  end

  @doc "Gets a session by token.\n"
  def get_session(token) when is_binary(token) do
    Session |> where([s], s.token == ^token) |> preload(:user) |> Repo.one()
  end

  @doc "Gets a session by token and validates it's not expired.\n"
  def get_valid_session(token) when is_binary(token) do
    case get_session(token) do
      %Session{} = session ->
        if Session.active?(session) do
          update_last_activity(session)
          {:ok, session}
        else
          delete_session(session)
          {:error, :expired}
        end

      nil ->
        {:error, :not_found}
    end
  end

  @doc "Updates the last activity time for a session.\n"
  def update_last_activity(%Session{} = session) do
    session |> Session.changeset(%{last_activity_at: DateTime.utc_now()}) |> Repo.update()
  end

  @doc "Invalidates a session by token.\n"
  def invalidate_session(token) when is_binary(token) do
    case get_session(token) do
      %Session{} = session -> delete_session(session)
      nil -> {:error, :not_found}
    end
  end

  @doc "Deletes a session.\n"
  def delete_session(%Session{} = session) do
    Repo.delete(session)
  end

  @doc "Lists all sessions for a user.\n"
  def list_user_sessions(%User{id: user_id}) do
    Session
    |> where([s], s.user_id == ^user_id)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  @doc "Invalidates all sessions for a user.\n"
  def invalidate_all_user_sessions(%User{id: user_id}) do
    Session |> where([s], s.user_id == ^user_id) |> Repo.delete_all()
  end

  @doc "Cleans up expired sessions.\n"
  def cleanup_expired_sessions do
    now = DateTime.utc_now()
    Session |> where([s], s.expires_at < ^now) |> Repo.delete_all()
  end

  @doc "Refreshes a session using refresh token.\n"
  def refresh_session(refresh_token) when is_binary(refresh_token) do
    Session
    |> where([s], s.refresh_token == ^refresh_token)
    |> preload(:user)
    |> Repo.one()
    |> case do
      %Session{} = session ->
        if Session.active?(session) do
          create_session(session.user)
        else
          delete_session(session)
          {:error, :expired}
        end

      nil ->
        {:error, :not_found}
    end
  end
end
