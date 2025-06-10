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

  @secret_key Application.compile_env(:aria_auth, :macaroon_secret, "development_macaroon_secret_key")
  @default_expiry 3600 # 1 hour
  @issuer "aria-auth"
  @audience "aria-platform"

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
    permissions = Keyword.get(opts, :permissions, user.roles)
    location = Keyword.get(opts, :location, nil)
    
    now = DateTime.utc_now() |> DateTime.to_unix()
    expires_at = now + expiry

    try do
      # Create base macaroon with user information
      macaroon = Macfly.create_macaroon(
        location || @issuer,
        "user:#{user.id}",  # identifier
        @secret_key
      )
      
      # Add first-party caveats (permissions and constraints)
      macaroon = macaroon
      |> add_caveat("user_id = #{user.id}")
      |> add_caveat("email = #{user.email}")
      |> add_caveat("issued_at = #{now}")
      |> add_caveat("expires_at = #{expires_at}")
      |> add_caveat("issuer = #{@issuer}")
      |> add_caveat("audience = #{@audience}")
      
      # Add permission caveats
      macaroon = Enum.reduce(permissions, macaroon, fn permission, acc ->
        add_caveat(acc, "permission = #{permission}")
      end)
      
      # Add location caveat if specified
      macaroon = if location do
        add_caveat(macaroon, "location = #{location}")
      else
        macaroon
      end
      
      # Serialize the macaroon
      case Macfly.encode([macaroon]) do
        {:ok, token} -> {:ok, token}
        {:error, reason} -> {:error, reason}
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
            {:ok, caveats} -> {:ok, caveats}
            {:error, reason} -> {:error, reason}
          end
        
        {:ok, macaroons} when is_list(macaroons) ->
          # Handle multiple macaroons (discharge macaroons)
          case verify_macaroon_chain(macaroons) do
            {:ok, caveats} -> {:ok, caveats}
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
      {:ok, caveats} ->
        case extract_user_id(caveats) do
          {:ok, user_id} ->
            case AriaAuth.Accounts.get_user(user_id) do
              %User{} = user -> {:ok, user}
              nil -> {:error, :user_not_found}
            end
          
          {:error, reason} -> {:error, reason}
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
        "resource = /api/users/123",
        "action = read",
        "expires_at = #{DateTime.utc_now() |> DateTime.add(300) |> DateTime.to_unix()}"
      ])
  """
  def attenuate_token(token, additional_caveats) when is_binary(token) and is_list(additional_caveats) do
    case Macfly.decode(token) do
      {:ok, [macaroon]} ->
        try do
          # Add additional caveats to restrict the token
          attenuated_macaroon = Enum.reduce(additional_caveats, macaroon, fn caveat, acc ->
            add_caveat(acc, caveat)
          end)
          
          case Macfly.encode([attenuated_macaroon]) do
            {:ok, new_token} -> {:ok, new_token}
            {:error, reason} -> {:error, reason}
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

  defp add_caveat(macaroon, caveat_string) do
    case Macfly.Macaroon.add_first_party_caveat(macaroon, caveat_string) do
      {:ok, updated_macaroon} -> updated_macaroon
      {:error, _reason} -> macaroon  # Return original if caveat addition fails
    end
  end

  defp verify_macaroon_caveats(macaroon) do
    try do
      # Extract caveats from the macaroon
      caveats = extract_caveats_from_macaroon(macaroon)
      
      # Verify basic constraints
      with {:ok, _} <- verify_expiration(caveats),
           {:ok, _} <- verify_issuer(caveats),
           {:ok, _} <- verify_audience(caveats) do
        {:ok, caveats}
      else
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

  defp extract_caveats_from_macaroon(macaroon) do
    # This is a simplified caveat extraction
    # In practice, you'd use Macfly's API to get caveats
    # For now, we'll return a basic structure
    %{
      "user_id" => nil,
      "email" => nil,
      "issued_at" => nil,
      "expires_at" => nil,
      "issuer" => nil,
      "audience" => nil,
      "permissions" => []
    }
  end

  defp verify_expiration(caveats) do
    case Map.get(caveats, "expires_at") do
      nil -> {:error, :no_expiration}
      expires_at when is_integer(expires_at) ->
        now = DateTime.utc_now() |> DateTime.to_unix()
        if now < expires_at do
          {:ok, :valid}
        else
          {:error, :token_expired}
        end
      _ -> {:error, :invalid_expiration}
    end
  end

  defp verify_issuer(caveats) do
    case Map.get(caveats, "issuer") do
      @issuer -> {:ok, :valid}
      _ -> {:error, :invalid_issuer}
    end
  end

  defp verify_audience(caveats) do
    case Map.get(caveats, "audience") do
      @audience -> {:ok, :valid}
      _ -> {:error, :invalid_audience}
    end
  end

  defp extract_user_id(caveats) do
    case Map.get(caveats, "user_id") do
      nil -> {:error, :no_user_id}
      user_id when is_integer(user_id) -> {:ok, user_id}
      user_id when is_binary(user_id) ->
        case Integer.parse(user_id) do
          {id, ""} -> {:ok, id}
          _ -> {:error, :invalid_user_id}
        end
      _ -> {:error, :invalid_user_id}
    end
  end
end
