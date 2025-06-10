defmodule AriaSecurity.Secrets.EctoBackend do
  @moduledoc "Ecto implementation of the secret management behaviour."
  @behaviour AriaSecurity.Secrets.Behaviour

  alias AriaSecurity.SecretsRepo
  alias AriaSecurity.Secret

  @impl true
  def get_secret(key) do
    case SecretsRepo.get_by(Secret, key: key) do
      nil -> {:error, :not_found}
      secret -> {:ok, secret.value}
    end
  end

  @impl true
  def set_secret(key, value) do
    case SecretsRepo.get_by(Secret, key: key) do
      nil -> # Insert new secret
        %Secret{}
        |> Secret.changeset(%{key: key, value: value})
        |> SecretsRepo.insert()
        |> case do
          {:ok, _} -> :ok
          {:error, changeset} -> {:error, changeset}
        end
      secret -> # Update existing secret
        secret
        |> Secret.changeset(%{value: value})
        |> SecretsRepo.update()
        |> case do
          {:ok, _} -> :ok
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @impl true
  def delete_secret(key) do
    case SecretsRepo.get_by(Secret, key: key) do
      nil -> {:error, :not_found}
      secret -> 
        SecretsRepo.delete(secret)
        |> case do
          {:ok, _} -> :ok
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @impl true
  def list_secrets() do
    secrets = SecretsRepo.all(Secret)
    {:ok, Enum.map(secrets, &(&1.key))}
  end
end
