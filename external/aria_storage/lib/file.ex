# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.File do
  @moduledoc "Ecto schema for tracking file metadata in the storage system.\n\nThis struct represents file records that track the relationship between\nuploaded files and their chunked storage representation.\n"
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema("storage_files") do
    field(:filename, :string)
    field(:content_type, :string)
    field(:size, :integer)
    field(:checksum, :string)
    field(:index_ref, :string)
    field(:metadata, :map, default: %{})
    field(:status, :string, default: "pending")
    field(:uploaded_at, :utc_datetime)
    timestamps()
  end

  @type t :: %__MODULE__{}
  @doc "Changeset for creating and updating file records.\n"
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(file, attrs) do
    file
    |> cast(attrs, [
      :filename,
      :content_type,
      :size,
      :checksum,
      :index_ref,
      :metadata,
      :status,
      :uploaded_at
    ])
    |> validate_required([:filename, :size])
    |> validate_inclusion(:status, ["pending", "chunked", "stored", "failed"])
    |> validate_number(:size, greater_than: 0)
    |> unique_constraint(:checksum)
    |> unique_constraint(:index_ref)
  end

  @doc "Changeset for marking a file as successfully stored.\n"
  @spec store_changeset(t(), String.t()) :: Ecto.Changeset.t()
  def store_changeset(file, index_ref) do
    file
    |> cast(%{index_ref: index_ref, status: "stored"}, [:index_ref, :status])
    |> validate_required([:index_ref])
  end

  @doc "Changeset for marking a file as failed.\n"
  @spec fail_changeset(t(), String.t()) :: Ecto.Changeset.t()
  def fail_changeset(file, reason) do
    metadata = Map.put(file.metadata || %{}, "failure_reason", reason)
    file |> cast(%{status: "failed", metadata: metadata}, [:status, :metadata])
  end
end
