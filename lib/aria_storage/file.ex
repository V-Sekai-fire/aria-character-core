# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.File do
  @moduledoc """
  Ecto schema for tracking file metadata in the storage system.

  This struct represents file records that track the relationship between
  uploaded files and their chunked storage representation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "storage_files" do
    field :filename, :string
    field :content_type, :string
    field :size, :integer
    field :checksum, :string
    field :index_ref, :string
    field :metadata, :map, default: %{}
    field :status, :string, default: "pending"
    field :uploaded_at, :utc_datetime

    timestamps()
  end

  @doc """
  Changeset for creating and updating file records.
  """
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:filename, :content_type, :size, :checksum, :index_ref, :metadata, :status, :uploaded_at])
    |> validate_required([:filename, :size])
    |> validate_inclusion(:status, ["pending", "chunked", "stored", "failed"])
    |> validate_number(:size, greater_than: 0)
    |> unique_constraint(:checksum)
    |> unique_constraint(:index_ref)
  end

  @doc """
  Changeset for marking a file as successfully stored.
  """
  def store_changeset(file, index_ref) do
    file
    |> cast(%{index_ref: index_ref, status: "stored"}, [:index_ref, :status])
    |> validate_required([:index_ref])
  end

  @doc """
  Changeset for marking a file as failed.
  """
  def fail_changeset(file, reason) do
    metadata = Map.put(file.metadata || %{}, "failure_reason", reason)

    file
    |> cast(%{status: "failed", metadata: metadata}, [:status, :metadata])
  end
end
