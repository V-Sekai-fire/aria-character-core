defmodule AriaSecurity.Secret do
  use Ecto.Schema
  use Ecto.Cloak
  import Ecto.Changeset

  schema "secrets" do
    field :key, :string
    cloak_field :value, :string

    timestamps()
  end

  def changeset(secret, attrs) do
    secret
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
    |> unique_constraint(:key)
  end
end
