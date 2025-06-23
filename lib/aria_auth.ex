# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth do
  @moduledoc "Top-level AriaAuth module providing convenience functions for authentication.\n\nThis module delegates to the AriaAuth app for token generation,\nverification, and user management.\n"

  @doc "Generates a macaroon token for a user.\n\nDelegates to the AriaAuth app.\n"
  def generate_token(user, _opts \\ []) do
    # Stub implementation - would delegate to aria_auth app
    {:ok, "stub_token_#{user}"}
  end

  @doc "Verifies a macaroon token and returns the parsed caveats.\n\nDelegates to the AriaAuth app.\n"
  def verify_token(_token) do
    # Stub implementation - would delegate to aria_auth app
    {:ok, %{user: "stub_user", caveats: []}}
  end

  @doc "Verifies a macaroon token and returns the associated user.\n\nDelegates to the AriaAuth app.\n"
  def verify_token_and_get_user(_token) do
    # Stub implementation - would delegate to aria_auth app
    {:ok, "stub_user"}
  end

  @doc "Attenuates (restricts) a macaroon by adding additional caveats.\n\nDelegates to the AriaAuth app.\n"
  def attenuate_token(token, _additional_caveats) do
    # Stub implementation - would delegate to aria_auth app
    {:ok, "attenuated_#{token}"}
  end

  @doc "Generates an access token and refresh token pair using macaroons.\n\nDelegates to the AriaAuth app.\n"
  def generate_token_pair(user) do
    # Stub implementation - would delegate to aria_auth app
    {:ok, %{access_token: "access_#{user}", refresh_token: "refresh_#{user}"}}
  end
end
