# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Utils do
  @spec calculate_index_checksum([%{id: binary()}]) :: binary()
  def calculate_index_checksum(chunks) do
    chunk_ids = Enum.map(chunks, & &1.id)
    combined = Enum.join(chunk_ids)
    :crypto.hash(:sha256, combined)
  end
end
