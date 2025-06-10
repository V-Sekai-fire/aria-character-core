defmodule AriaSecurity.Crypto do
  @moduledoc "Cryptographic operations using ex_crypto."

  # Placeholder for functions that might use ex_crypto
  # Example: key generation, signing, verification, hashing

  def generate_random_bytes(length) do
    :crypto.strong_rand_bytes(length)
  end

  # Add more ex_crypto related functions as needed
end
