# AriaAuth

Authentication and authorization system for Aria applications.

## Features

- User account management
- Session handling
- Macaroon-based authentication tokens
- Secure password hashing with bcrypt

## Modules

- `AriaAuth.Accounts` - User account management
- `AriaAuth.Sessions` - Session handling
- `AriaAuth.Macaroons` - Token-based authentication
- `AriaAuth.Repo` - Database repository

## Usage

Add to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:aria_auth, in_umbrella: true}
  ]
end
```

## Testing

Run tests with:

```bash
cd apps/aria_auth
mix test
```

## Dependencies

- Ecto for database operations
- BCrypt for password hashing
- Jason for JSON handling
- PostgreSQL adapter
