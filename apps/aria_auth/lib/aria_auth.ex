# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaAuth do
  @moduledoc """
  Main AriaAuth module providing convenient access to authentication functionality.

  This module delegates to the appropriate submodules for different authentication operations.
  """

  alias AriaAuth.{Accounts, Macaroons, Sessions}

  # Delegate macaroon operations
  defdelegate generate_token(user, opts \\ []), to: Macaroons
  defdelegate verify_token(token), to: Macaroons
  defdelegate verify_token_and_get_user(token), to: Macaroons
  defdelegate attenuate_token(token, caveats), to: Macaroons
  defdelegate generate_token_pair(user), to: Macaroons

  # Delegate account operations
  defdelegate get_user(id), to: Accounts
  defdelegate create_user(attrs), to: Accounts
  defdelegate update_user(user, attrs), to: Accounts
  defdelegate delete_user(user), to: Accounts
  defdelegate authenticate_user(email, password), to: Accounts

  # Delegate session operations
  defdelegate create_session(user), to: Sessions
  defdelegate get_session(token), to: Sessions
  defdelegate delete_session(token), to: Sessions
end
