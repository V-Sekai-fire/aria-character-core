# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.Sessions do
  @moduledoc """
  The Sessions context for managing user sessions.
  """

  import Ecto.Query, warn: false
  alias AriaData.AuthRepo
  alias AriaAuth.Sessions.Session
  alias AriaAuth.Accounts.User

  @doc """
  Creates a session for a user.
  """
  def create_session(%User{} = user, attrs \\ %{}) do
    %Session{}
    |> Session.create_changeset(user, attrs)
    |> AuthRepo.insert()
  end

  @doc """
  Gets a session by token.
  """
  def get_session(token) when is_binary(token) do
    Session
    |> where([s], s.token == ^token)
    |> preload(:user)
    |> AuthRepo.one()
  end

  @doc """
  Gets a session by token and validates it's not expired.
  """
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

  @doc """
  Updates the last activity time for a session.
  """
  def update_last_activity(%Session{} = session) do
    session
    |> Session.changeset(%{last_activity_at: DateTime.utc_now()})
    |> AuthRepo.update()
  end

  @doc """
  Invalidates a session by token.
  """
  def invalidate_session(token) when is_binary(token) do
    case get_session(token) do
      %Session{} = session ->
        delete_session(session)
      
      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Deletes a session.
  """
  def delete_session(%Session{} = session) do
    AuthRepo.delete(session)
  end

  @doc """
  Lists all sessions for a user.
  """
  def list_user_sessions(%User{id: user_id}) do
    Session
    |> where([s], s.user_id == ^user_id)
    |> order_by([s], desc: s.inserted_at)
    |> AuthRepo.all()
  end

  @doc """
  Invalidates all sessions for a user.
  """
  def invalidate_all_user_sessions(%User{id: user_id}) do
    Session
    |> where([s], s.user_id == ^user_id)
    |> AuthRepo.delete_all()
  end

  @doc """
  Cleans up expired sessions.
  """
  def cleanup_expired_sessions do
    now = DateTime.utc_now()
    
    Session
    |> where([s], s.expires_at < ^now)
    |> AuthRepo.delete_all()
  end

  @doc """
  Refreshes a session using refresh token.
  """
  def refresh_session(refresh_token) when is_binary(refresh_token) do
    Session
    |> where([s], s.refresh_token == ^refresh_token)
    |> preload(:user)
    |> AuthRepo.one()
    |> case do
      %Session{} = session ->
        if Session.active?(session) do
          # Create new session
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
