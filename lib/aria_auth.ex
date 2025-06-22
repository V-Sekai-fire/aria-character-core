# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth do
  @moduledoc """
  Top-level AriaAuth module providing convenience functions for authentication.

  This module delegates to the appropriate sub-modules for token generation,
  verification, and user management.
  """

  alias AriaAuth.Accounts.User

  @type token :: String.t()
  @type user :: User.t()
  @type permissions :: [String.t()]
  @type caveats :: [term()]
  @type token_pair :: %{access_token: token(), refresh_token: token()}
  @type verification_result :: %{user_id: String.t(), permissions: permissions()}
  @type opts :: keyword()

  @doc """
  Generates a macaroon token for a user.

  Delegates to AriaAuth.Macaroons.generate_token/2.
  """
  @spec generate_token(user(), opts()) :: {:ok, token()} | {:error, term()}
  defdelegate generate_token(user, opts \\ []), to: AriaAuth.Macaroons

  @doc """
  Verifies a macaroon token and returns the parsed caveats.

  Delegates to AriaAuth.Macaroons.verify_token/1.
  """
  @spec verify_token(token()) :: {:ok, verification_result()} | {:error, term()}
  defdelegate verify_token(token), to: AriaAuth.Macaroons

  @doc """
  Verifies a macaroon token and returns the associated user.

  Delegates to AriaAuth.Macaroons.verify_token_and_get_user/1.
  """
  @spec verify_token_and_get_user(token()) :: {:ok, user(), permissions()} | {:error, term()}
  defdelegate verify_token_and_get_user(token), to: AriaAuth.Macaroons

  @doc """
  Attenuates (restricts) a macaroon by adding additional caveats.

  Delegates to AriaAuth.Macaroons.attenuate_token/2.
  """
  @spec attenuate_token(token(), caveats()) :: {:ok, token()} | {:error, term()}
  defdelegate attenuate_token(token, additional_caveats), to: AriaAuth.Macaroons

  @doc """
  Generates an access token and refresh token pair using macaroons.

  Delegates to AriaAuth.Macaroons.generate_token_pair/1.
  """
  @spec generate_token_pair(user()) :: {:ok, token_pair()} | {:error, term()}
  defdelegate generate_token_pair(user), to: AriaAuth.Macaroons
end
