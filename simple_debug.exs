# Simple test for macaroon caveat debugging
alias AriaAuth.{Macaroons, Accounts.User}
alias Macaroons.{PermissionsCaveat, ConfineUserString}

test_user = %User{
  id: "test-user-123",
  email: "test@example.com",
  roles: ["user", "editor"]
}

{:ok, token} = Macaroons.generate_token(test_user)
{:ok, [macaroon]} = Macfly.decode(token)

IO.puts("Number of caveats: #{length(macaroon.caveats)}")

Enum.with_index(macaroon.caveats, fn caveat, index ->
  IO.puts("Caveat #{index}: #{inspect(caveat.__struct__)}")
  IO.puts("  Content: #{inspect(caveat)}")
end)
