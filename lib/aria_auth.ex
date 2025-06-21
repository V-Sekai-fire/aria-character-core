# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth do
  @moduledoc """
  Top-level AriaAuth module providing convenience functions for authentication.

  This module delegates to the appropriate sub-modules for token generation,
  verification, and user management.
  """

  @doc """
  Generates a macaroon token for a user.

  Delegates to AriaAuth.Macaroons.generate_token/2.
  """
  defdelegate generate_token(user, opts \\ []), to: AriaAuth.Macaroons

  @doc """
  Verifies a macaroon token and returns the parsed caveats.

  Delegates to AriaAuth.Macaroons.verify_token/1.
  """
  defdelegate verify_token(token), to: AriaAuth.Macaroons

  @doc """
  Verifies a macaroon token and returns the associated user.

  Delegates to AriaAuth.Macaroons.verify_token_and_get_user/1.
  """
  defdelegate verify_token_and_get_user(token), to: AriaAuth.Macaroons

  @doc """
  Attenuates (restricts) a macaroon by adding additional caveats.

  Delegates to AriaAuth.Macaroons.attenuate_token/2.
  """
  defdelegate attenuate_token(token, additional_caveats), to: AriaAuth.Macaroons

  @doc """
  Generates an access token and refresh token pair using macaroons.

  Delegates to AriaAuth.Macaroons.generate_token_pair/1.
  """
  defdelegate generate_token_pair(user), to: AriaAuth.Macaroons
end
