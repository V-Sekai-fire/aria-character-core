# Detailed debug script to understand macaroon internals
# Usage: cd /Users/setup/Developer/aria-character-core && elixir -S mix run debug_macaroons_detailed.exs

alias AriaAuth.{Macaroons, Accounts.User}
alias Macaroons.{PermissionsCaveat, ConfineUserString}
alias Macfly.Caveat.ValidityWindow

# Create a test user
test_user = %User{
  id: "test-user-123",
  email: "test@example.com",
  roles: ["user", "editor"]
}

IO.puts("=== GENERATING TOKEN ===")

case Macaroons.generate_token(test_user) do
  {:ok, token} -> 
    IO.puts("✅ Token generated successfully!")
    IO.inspect(token, label: "Generated token")
    
    IO.puts("\n=== DECODING TOKEN ===")
    case Macfly.decode(token) do
      {:ok, [macaroon]} ->
        IO.puts("✅ Token decoded successfully!")
        IO.inspect(macaroon, label: "Decoded macaroon", structs: false)
        
        IO.puts("\n=== EXAMINING CAVEATS ===")
        IO.inspect(macaroon.caveats, label: "Raw caveats")
        
        # Check each caveat type
        Enum.with_index(macaroon.caveats, fn caveat, index ->
          IO.puts("\n--- Caveat #{index} ---")
          IO.inspect(caveat, label: "Caveat struct")
          IO.inspect(caveat.__struct__, label: "Caveat type")
        end)
        
        # Try to find specific caveats
        IO.puts("\n=== SEARCHING FOR CUSTOM CAVEATS ===")
        
        user_caveat = Enum.find(macaroon.caveats, fn caveat -> 
          match?(%ConfineUserString{}, caveat) 
        end)
        IO.inspect(user_caveat, label: "Found ConfineUserString caveat")
        
        perms_caveat = Enum.find(macaroon.caveats, fn caveat -> 
          match?(%PermissionsCaveat{}, caveat) 
        end)
        IO.inspect(perms_caveat, label: "Found PermissionsCaveat")
        
        validity_caveat = Enum.find(macaroon.caveats, fn caveat -> 
          match?(%ValidityWindow{}, caveat) 
        end)
        IO.inspect(validity_caveat, label: "Found ValidityWindow caveat")
        
      {:error, reason} ->
        IO.puts("❌ Token decoding failed:")
        IO.inspect(reason, label: "Decode error")
    end
    
  {:error, reason} -> 
    IO.puts("❌ Token generation failed:")
    IO.inspect(reason, label: "Generation error")
end
