# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.FileRecord do
  @moduledoc """
  File record schema for AriaStorage.

  This module defines the structure for file metadata records
  stored in the database. Currently contains stubs for future
  implementation with proper Ecto schema.
  """

  # TODO: Replace with proper Ecto schema when database integration is added
  # use Ecto.Schema
  # import Ecto.Changeset

  defstruct [
    :id,
    :filename,
    :size,
    :content_type,
    :checksum,
    :chunks,
    :index_ref,
    :metadata,
    :user_id,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    filename: String.t() | nil,
    size: non_neg_integer() | nil,
    content_type: String.t() | nil,
    checksum: binary() | nil,
    chunks: list() | nil,
    index_ref: String.t() | nil,
    metadata: map() | nil,
    user_id: String.t() | nil,
    created_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }

  @doc """
  Schema introspection function (stub for Ecto compatibility).

  ## Parameters
  - atom: The schema attribute to query

  ## Returns
  - Schema information based on the attribute
  """
  def __schema__(atom) do
    case atom do
      :fields ->
        [:id, :filename, :size, :content_type, :checksum, :chunks,
         :index_ref, :metadata, :user_id, :created_at, :updated_at]

      :primary_key ->
        [:id]

      :type ->
        %{
          id: :string,
          filename: :string,
          size: :integer,
          content_type: :string,
          checksum: :binary,
          chunks: {:array, :map},
          index_ref: :string,
          metadata: :map,
          user_id: :string,
          created_at: :utc_datetime,
          updated_at: :utc_datetime
        }

      _ ->
        nil
    end
  end

  @doc """
  Creates a new file record.

  ## Parameters
  - attrs: Attributes for the file record

  ## Returns
  - %FileRecord{} struct
  """
  def new(attrs \\ %{}) do
    struct(__MODULE__, attrs)
  end
end
