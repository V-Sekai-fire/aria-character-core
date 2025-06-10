# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth do
  @moduledoc """
  AriaAuth provides authentication and authorization services for the Aria platform.
  
  This service handles:
  - User authentication (login/logout)
  - Session management
  - OAuth2/OIDC integration
  - Macaroon token management
  - WebRTC-based identity verification
  - User profile management
  """

  alias AriaAuth.{Accounts, Sessions}

  @doc """
  Authenticates a user with email and password.
  """
  defdelegate authenticate_user(email, password), to: Accounts

  @doc """
  Creates a new user account.
  """
  defdelegate create_user(attrs), to: Accounts

  @doc """
  Gets a user by id.
  """
  defdelegate get_user(id), to: Accounts

  @doc """
  Gets a user by email.
  """
  defdelegate get_user_by_email(email), to: Accounts

  @doc """
  Updates user information.
  """
  defdelegate update_user(user, attrs), to: Accounts

  @doc """
  Creates a new session for a user.
  """
  defdelegate create_session(user), to: Sessions

  @doc """
  Gets a session by token.
  """
  defdelegate get_session(token), to: Sessions

  @doc """
  Invalidates a session.
  """
  defdelegate invalidate_session(token), to: Sessions

  @doc """
  Generates a macaroon token for the given user.
  """
  defdelegate generate_token(user), to: AriaAuth.Macaroons

  @doc """
  Verifies a macaroon token.
  """
  defdelegate verify_token(token), to: AriaAuth.Macaroons
end