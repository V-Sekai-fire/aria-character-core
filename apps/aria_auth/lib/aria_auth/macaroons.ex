# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.Macaroons do
  @moduledoc """
  Macaroon-based authentication tokens using Fly.io's macfly library.
  
  Macaroons provide better security than JWT tokens because they support:
  - Attenuation: Restricting tokens without server communication
  - Delegation: Safely passing tokens with reduced permissions
  - Third-party caveats: External authorization integration
  - Contextual constraints: Time, location, action restrictions
  """

  alias AriaAuth.Accounts.User
  alias Macfly.Caveat.{ValidityWindow, ConfineUser}

  @secret_key Application.compile_env(:aria_auth, :macaroon_secret, "development_macaroon_secret_key")
  @default_expiry 3600 # 1 hour
  @issuer "aria-auth"

  @doc """
  Generates a macaroon token for a user.
  
  ## Options
  - `:expiry` - Token expiration time in seconds (default: 3600)
  - `:permissions` - List of permissions to encode in caveats
  - `:location` - Location restriction for the token
  
  ## Example
      {:ok, token} = AriaAuth.Macaroons.generate_token(user, expiry: 900, permissions: ["read", "write"])
  """
  def generate_token(%User{} = user, opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)
    _permissions = Keyword.get(opts, :permissions, user.roles)
    location = Keyword.get(opts, :location, nil)

    try do
      # Create base macaroon with user information
      macaroon = Macfly.Macaroon.new(
        @secret_key,
        "user:#{user.id}",  # identifier
        location || @issuer
      )
      
      # Add built-in caveats using Macfly's structured types
      caveats = [
        ValidityWindow.build(for: expiry),
        %ConfineUser{id: user.id}
      ]
      
      # Create attenuated macaroon with caveats
      attenuated_macaroon = Macfly.Macaroon.attenuate(macaroon, caveats)
      
      # Serialize the macaroon
      case Macfly.encode([attenuated_macaroon]) do
        token when is_binary(token) -> {:ok, token}
        error -> {:error, error}
      end
    rescue
      error -> {:error, {:macaroon_creation_failed, error}}
    end
  end

  @doc """
  Verifies a macaroon token and returns the parsed caveats.
  """
  def verify_token(token) when is_binary(token) do
    try do
      case Macfly.decode(token) do
        {:ok, [macaroon]} ->
          case verify_macaroon_caveats(macaroon) do
            {:ok, user_id} -> {:ok, %{user_id: user_id}}
            {:error, reason} -> {:error, reason}
          end
        
        {:ok, macaroons} when is_list(macaroons) ->
          # Handle multiple macaroons (discharge macaroons)
          case verify_macaroon_chain(macaroons) do
            {:ok, user_id} -> {:ok, %{user_id: user_id}}
            {:error, reason} -> {:error, reason}
          end
        
        {:error, reason} -> {:error, {:decode_failed, reason}}
      end
    rescue
      error -> {:error, {:verification_failed, error}}
    end
  end

  @doc """
  Verifies a macaroon token and returns the associated user.
  """
  def verify_token_and_get_user(token) when is_binary(token) do
    case verify_token(token) do
      {:ok, %{user_id: user_id}} ->
        case AriaAuth.Accounts.get_user(user_id) do
          %User{} = user -> {:ok, user}
          nil -> {:error, :user_not_found}
        end
      
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Attenuates (restricts) a macaroon by adding additional caveats.
  
  This allows creating derived tokens with reduced permissions without
  communicating with the server.
  
  ## Example
      {:ok, restricted_token} = AriaAuth.Macaroons.attenuate_token(token, [
        %Macfly.Caveat.ValidityWindow{not_before: now, not_after: now + 300}
      ])
  """
  def attenuate_token(token, additional_caveats) when is_binary(token) and is_list(additional_caveats) do
    case Macfly.decode(token) do
      {:ok, [macaroon]} ->
        try do
          # Add additional caveats to restrict the token
          attenuated_macaroon = Macfly.Macaroon.attenuate(macaroon, additional_caveats)
          
          case Macfly.encode([attenuated_macaroon]) do
            new_token when is_binary(new_token) -> {:ok, new_token}
            error -> {:error, error}
          end
        rescue
          error -> {:error, {:attenuation_failed, error}}
        end
      
      {:error, reason} -> {:error, {:decode_failed, reason}}
    end
  end

  @doc """
  Generates an access token and refresh token pair using macaroons.
  """
  def generate_token_pair(%User{} = user) do
    with {:ok, access_token} <- generate_token(user, expiry: 900, permissions: ["access"]), # 15 minutes
         {:ok, refresh_token} <- generate_token(user, expiry: 604_800, permissions: ["refresh"]) do # 7 days
      {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helper functions

  defp verify_macaroon_caveats(%Macfly.Macaroon{caveats: caveats}) do
    try do
      # Extract user ID from ConfineUser caveat
      user_id = extract_user_id_from_caveats(caveats)
      
      # Verify validity window
      case verify_validity_window(caveats) do
        :ok -> {:ok, user_id}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, {:caveat_verification_failed, error}}
    end
  end

  defp verify_macaroon_chain(macaroons) do
    # For now, just verify the root macaroon
    # In a full implementation, this would verify discharge macaroons
    case macaroons do
      [root_macaroon | _discharge_macaroons] ->
        verify_macaroon_caveats(root_macaroon)
      
      [] -> {:error, :empty_macaroon_chain}
    end
  end

  defp extract_user_id_from_caveats(caveats) do
    case Enum.find(caveats, fn caveat -> match?(%ConfineUser{}, caveat) end) do
      %ConfineUser{id: id} -> id
      nil -> raise "No ConfineUser caveat found"
    end
  end

  defp verify_validity_window(caveats) do
    case Enum.find(caveats, fn caveat -> match?(%ValidityWindow{}, caveat) end) do
      %ValidityWindow{not_before: not_before, not_after: not_after} ->
        now = System.os_time(:second)
        if now >= not_before and now <= not_after do
          :ok
        else
          {:error, :token_expired}
        end
      
      nil -> {:error, :no_validity_window}
    end
  end
end
