# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.Tokens do
  @moduledoc """
  The Tokens context for JWT token management.
  """

  alias AriaAuth.Accounts.User

  @secret_key Application.compile_env(:aria_auth, :jwt_secret, "development_jwt_secret_key")
  @default_expiry 3600 # 1 hour

  @doc """
  Generates a JWT token for a user.
  """
  def generate_token(%User{} = user, opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)
    now = DateTime.utc_now() |> DateTime.to_unix()

    claims = %{
      "sub" => user.id,
      "email" => user.email,
      "roles" => user.roles,
      "iat" => now,
      "exp" => now + expiry,
      "iss" => "aria-auth",
      "aud" => "aria-platform"
    }

    case Joken.generate_and_sign(claims, create_signer()) do
      {:ok, token, _claims} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Verifies a JWT token and returns the claims.
  """
  def verify_token(token) when is_binary(token) do
    case Joken.verify_and_validate(token, create_signer()) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Verifies a JWT token and returns the user.
  """
  def verify_token_and_get_user(token) when is_binary(token) do
    case verify_token(token) do
      {:ok, %{"sub" => user_id}} ->
        case AriaAuth.Accounts.get_user(user_id) do
          %User{} = user -> {:ok, user}
          nil -> {:error, :user_not_found}
        end
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Decodes a JWT token without verification (useful for getting user info from expired tokens).
  """
  def decode_token(token) when is_binary(token) do
    case Joken.peek_claims(token) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generates an access token and refresh token pair.
  """
  def generate_token_pair(%User{} = user) do
    with {:ok, access_token} <- generate_token(user, expiry: 900), # 15 minutes
         {:ok, refresh_token} <- generate_token(user, expiry: 604_800) do # 7 days
      {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_signer do
    Joken.Signer.create("HS256", @secret_key)
  end
end
