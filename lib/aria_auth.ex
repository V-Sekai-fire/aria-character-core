defmodule AriaAuth do
  @moduledoc "Top-level AriaAuth module providing convenience functions for authentication.\n\nThis module delegates to the appropriate sub-modules for token generation,\nverification, and user management.\n"
  @doc "Generates a macaroon token for a user.\n\nDelegates to AriaAuth.Macaroons.generate_token/2.\n"
  defdelegate generate_token(user, opts \\ []), to: AriaAuth.Macaroons

  @doc "Verifies a macaroon token and returns the parsed caveats.\n\nDelegates to AriaAuth.Macaroons.verify_token/1.\n"
  defdelegate verify_token(token), to: AriaAuth.Macaroons

  @doc "Verifies a macaroon token and returns the associated user.\n\nDelegates to AriaAuth.Macaroons.verify_token_and_get_user/1.\n"
  defdelegate verify_token_and_get_user(token), to: AriaAuth.Macaroons

  @doc "Attenuates (restricts) a macaroon by adding additional caveats.\n\nDelegates to AriaAuth.Macaroons.attenuate_token/2.\n"
  defdelegate attenuate_token(token, additional_caveats), to: AriaAuth.Macaroons

  @doc "Generates an access token and refresh token pair using macaroons.\n\nDelegates to AriaAuth.Macaroons.generate_token_pair/1.\n"
  defdelegate generate_token_pair(user), to: AriaAuth.Macaroons
end