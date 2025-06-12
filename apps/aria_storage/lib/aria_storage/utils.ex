defmodule AriaStorage.Utils do
  def calculate_index_checksum(chunks) do
    chunk_ids = Enum.map(chunks, & &1.id)
    combined = Enum.join(chunk_ids)
    :crypto.hash(:sha256, combined)
  end
end
