defmodule AriaSecurity.Secrets.EctoBackend do
  @moduledoc """
  Ecto implementation of the secret management behaviour.
  Stores secrets in a database using Ecto and SQLite.
  """
  @behaviour AriaSecurity.Secrets.Behaviour

  import Ecto.Query, warn: false
  alias AriaSecurity.Secret
  alias AriaSecurity.SecretsRepo
  alias Jason # Add Jason alias

  @impl true
  def get(key) do
    case SecretsRepo.get_by(Secret, key: key) do
      %Secret{value: value} ->
        # Value is decrypted by Ecto.Cloak automatically
        # Decode JSON string back to map
        case Jason.decode(value) do
          {:ok, decoded_value} -> {:ok, decoded_value}
          {:error, _} -> {:error, :json_decoding_failed}
        end
      nil -> {:error, :not_found}
    end
  end

  @impl true
  def put(key, value) do
    # Encode value to JSON string before saving
    case Jason.encode(value) do
      {:ok, json_value} ->
        case SecretsRepo.get_by(Secret, key: key) do
          %Secret{} = secret ->
            # Update existing secret
            secret
            |> Secret.changeset(%{value: json_value})
            |> SecretsRepo.update()
            |> case do
              {:ok, _} -> :ok
              {:error, changeset} -> {:error, changeset}
            end
          nil ->
            # Insert new secret
            %Secret{}
            |> Secret.changeset(%{key: key, value: json_value})
            |> SecretsRepo.insert()
            |> case do
              {:ok, _} -> :ok
              {:error, changeset} -> {:error, changeset}
            end
        end
      {:error, _} ->
        {:error, :json_encoding_failed}
    end
  end

  @impl true
  def delete(key) do
    case SecretsRepo.get_by(Secret, key: key) do
      %Secret{} = secret ->
        SecretsRepo.delete(secret)
        |> case do
          {:ok, _} -> :ok
          {:error, changeset} -> {:error, changeset}
        end
      nil ->
        {:error, :not_found}
    end
  end

  @impl true
  def list do
    secrets = SecretsRepo.all(from s in Secret, select: s.key)
    {:ok, secrets}
  end
end
