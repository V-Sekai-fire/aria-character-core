# Debug script to test macaroon functionality step by step
# Usage: cd /Users/setup/Developer/aria-character-core && elixir -S mix run debug_macaroons.exs

alias AriaAuth.{Macaroons, Accounts.User}
alias Macaroons.{PermissionsCaveat, ConfineUserString}
alias Macfly.Caveat.ValidityWindow

# Create a test user
test_user = %User{
  id: "test-user-123",
  email: "test@example.com",
  roles: ["user", "editor"]
}

IO.puts("Testing ConfineUserString caveat creation...")
user_caveat = ConfineUserString.build(test_user.id)
IO.inspect(user_caveat, label: "ConfineUserString caveat")

IO.puts("\nTesting PermissionsCaveat creation...")
perms_caveat = PermissionsCaveat.build(test_user.roles)
IO.inspect(perms_caveat, label: "PermissionsCaveat")

IO.puts("\nTesting ValidityWindow caveat creation...")
validity_caveat = ValidityWindow.build(for: 3600)
IO.inspect(validity_caveat, label: "ValidityWindow caveat")

IO.puts("\nTesting protocol implementations...")
IO.inspect(Macfly.Caveat.name(user_caveat), label: "ConfineUserString name")
IO.inspect(Macfly.Caveat.type(user_caveat), label: "ConfineUserString type")
IO.inspect(Macfly.Caveat.body(user_caveat), label: "ConfineUserString body")

IO.inspect(Macfly.Caveat.name(perms_caveat), label: "PermissionsCaveat name")
IO.inspect(Macfly.Caveat.type(perms_caveat), label: "PermissionsCaveat type")
IO.inspect(Macfly.Caveat.body(perms_caveat), label: "PermissionsCaveat body")

IO.puts("\nTesting token generation...")
case Macaroons.generate_token(test_user) do
  {:ok, token} -> 
    IO.puts("✅ Token generated successfully!")
    IO.inspect(String.length(token), label: "Token length")
    
    IO.puts("\nTesting token verification...")
    case Macaroons.verify_token(token) do
      {:ok, result} ->
        IO.puts("✅ Token verified successfully!")
        IO.inspect(result, label: "Verification result")
      {:error, reason} ->
        IO.puts("❌ Token verification failed:")
        IO.inspect(reason, label: "Error")
    end
    
  {:error, reason} -> 
    IO.puts("❌ Token generation failed:")
    IO.inspect(reason, label: "Error")
end
