# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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
  alias Macfly.Caveat.ValidityWindow

  @secret_key Application.compile_env(
                :aria_auth,
                :macaroon_secret,
                "development_macaroon_secret_key"
              )
  @default_expiry 3600
  @issuer "aria-auth"

  @doc "Generates a macaroon token for a user.\n\n## Options\n- `:expiry` - Token expiration time in seconds (default: 3600)\n- `:permissions` - List of permissions to encode in caveats\n- `:location` - Location restriction for the token\n\n## Example\n    {:ok, token} = AriaAuth.Macaroons.generate_token(user, expiry: 900, permissions: [\"read\", \"write\"])\n"
  def generate_token(%User{} = user, opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)
    permissions = Keyword.get(opts, :permissions, user.roles)
    location = Keyword.get(opts, :location, nil)

    try do
      macaroon =
        Macfly.Macaroon.new(
          @secret_key,
          "user:#{user.id}",
          location || @issuer
        )

      caveats = [
        ValidityWindow.build(for: expiry),
        AriaAuth.Macaroons.ConfineUserString.build(user.id),
        AriaAuth.Macaroons.PermissionsCaveat.build(permissions)
      ]

      attenuated_macaroon = Macfly.Macaroon.attenuate(macaroon, caveats)

      case Macfly.encode([attenuated_macaroon]) do
        token when is_binary(token) -> {:ok, token}
        error -> {:error, error}
      end
    rescue
      error -> {:error, {:macaroon_creation_failed, error}}
    end
  end

  @doc "Verifies a macaroon token and returns the parsed caveats.\n"
  def verify_token(token) when is_binary(token) do
    try do
      options =
        Macfly.Options.with_caveats(
          %Macfly.Options{},
          [AriaAuth.Macaroons.PermissionsCaveat, AriaAuth.Macaroons.ConfineUserString]
        )

      case Macfly.decode(token, options) do
        {:ok, [macaroon]} ->
          case verify_macaroon_caveats(macaroon) do
            {:ok, {user_id, permissions}} -> {:ok, %{user_id: user_id, permissions: permissions}}
            {:error, reason} -> {:error, reason}
          end

        {:ok, macaroons} when is_list(macaroons) ->
          case verify_macaroon_chain(macaroons) do
            {:ok, {user_id, permissions}} -> {:ok, %{user_id: user_id, permissions: permissions}}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, {:decode_failed, reason}}
      end
    rescue
      error -> {:error, {:verification_failed, error}}
    end
  end

  @doc "Verifies a macaroon token and returns the associated user.\n"
  def verify_token_and_get_user(token) when is_binary(token) do
    case verify_token(token) do
      {:ok, %{user_id: user_id, permissions: permissions}} ->
        case AriaAuth.Accounts.get_user(user_id) do
          %User{} = user -> {:ok, user, permissions}
          nil -> {:error, :user_not_found}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Attenuates (restricts) a macaroon by adding additional caveats.\n\nThis allows creating derived tokens with reduced permissions without\ncommunicating with the server.\n\n## Example\n    {:ok, restricted_token} = AriaAuth.Macaroons.attenuate_token(token, [\n      %Macfly.Caveat.ValidityWindow{not_before: now, not_after: now + 300}\n    ])\n"
  def attenuate_token(token, additional_caveats)
      when is_binary(token) and is_list(additional_caveats) do
    options =
      Macfly.Options.with_caveats(
        %Macfly.Options{},
        [AriaAuth.Macaroons.PermissionsCaveat, AriaAuth.Macaroons.ConfineUserString]
      )

    case Macfly.decode(token, options) do
      {:ok, [macaroon]} ->
        try do
          attenuated_macaroon = Macfly.Macaroon.attenuate(macaroon, additional_caveats)

          case Macfly.encode([attenuated_macaroon]) do
            new_token when is_binary(new_token) -> {:ok, new_token}
            error -> {:error, error}
          end
        rescue
          error -> {:error, {:attenuation_failed, error}}
        end

      {:error, reason} ->
        {:error, {:decode_failed, reason}}
    end
  end

  @doc "Generates an access token and refresh token pair using macaroons.\n"
  def generate_token_pair(%User{} = user) do
    with {:ok, access_token} <- generate_token(user, expiry: 900, permissions: ["access"]),
         {:ok, refresh_token} <- generate_token(user, expiry: 604_800, permissions: ["refresh"]) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp verify_macaroon_caveats(%Macfly.Macaroon{caveats: caveats}) do
    try do
      user_id = extract_user_id_from_caveats(caveats)
      permissions = extract_permissions_from_caveats(caveats)

      case verify_validity_window(caveats) do
        :ok -> {:ok, {user_id, permissions}}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, {:caveat_verification_failed, error}}
    end
  end

  defp verify_macaroon_chain(macaroons) do
    case macaroons do
      [root_macaroon | _discharge_macaroons] -> verify_macaroon_caveats(root_macaroon)
      [] -> {:error, :empty_macaroon_chain}
    end
  end

  defp extract_user_id_from_caveats(caveats) do
    case Enum.find(caveats, fn caveat -> match?(%AriaAuth.Macaroons.ConfineUserString{}, caveat) end) do
      %AriaAuth.Macaroons.ConfineUserString{id: id} -> id
      nil -> raise "No ConfineUserString caveat found"
    end
  end

  defp extract_permissions_from_caveats(caveats) do
    case Enum.find(caveats, fn caveat -> match?(%AriaAuth.Macaroons.PermissionsCaveat{}, caveat) end) do
      %AriaAuth.Macaroons.PermissionsCaveat{permissions: permissions} -> permissions
      nil -> []
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

      nil ->
        {:error, :no_validity_window}
    end
  end
end
