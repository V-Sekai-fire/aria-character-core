# AriaAuth

AriaAuth provides authentication and session management for the Aria Character Core system. It handles user accounts, secure sessions, and authorization using modern cryptographic techniques.

## Overview

AriaAuth implements a secure authentication system with:

- **Account Management**: User registration, login, and profile management
- **Session Management**: Secure session handling with automatic expiration
- **Macaroon-based Authorization**: Cryptographic tokens with capability-based security
- **Database Integration**: Persistent storage of user data and sessions

## Core Components

### Account Management
- `AriaAuth.Accounts` - User account creation, authentication, and management
- User registration with secure password hashing
- Account verification and password reset functionality

### Session Management
- `AriaAuth.Sessions` - Session creation, validation, and cleanup
- Automatic session expiration and renewal
- Secure session token generation

### Macaroon Authorization
- `AriaAuth.Macaroons` - Cryptographic authorization tokens
- Capability-based access control
- Token delegation and attenuation

### Database Layer
- `AriaAuth.Repo` - Database repository for persistent storage
- User account persistence
- Session storage and cleanup

## Usage

### User Registration

```elixir
# Register a new user
{:ok, user} = AriaAuth.Accounts.register_user(%{
  email: "user@example.com",
  password: "secure_password",
  username: "username"
})
```

### Authentication

```elixir
# Authenticate user credentials
case AriaAuth.Accounts.authenticate_user("user@example.com", "password") do
  {:ok, user} -> 
    # Create session
    {:ok, session} = AriaAuth.Sessions.create_session(user)
  {:error, :invalid_credentials} -> 
    # Handle authentication failure
end
```

### Session Management

```elixir
# Validate existing session
case AriaAuth.Sessions.get_session(session_token) do
  {:ok, session} -> 
    # Session is valid, proceed
  {:error, :expired} -> 
    # Session expired, require re-authentication
  {:error, :not_found} -> 
    # Invalid session token
end
```

### Macaroon Authorization

```elixir
# Create authorization macaroon
macaroon = AriaAuth.Macaroons.create_macaroon(
  location: "aria-system",
  key: secret_key,
  identifier: user_id
)

# Add capability restrictions
restricted_macaroon = AriaAuth.Macaroons.add_first_party_caveat(
  macaroon,
  "action = read"
)

# Verify macaroon
case AriaAuth.Macaroons.verify_macaroon(macaroon, secret_key, caveats) do
  {:ok, _} -> # Authorization granted
  {:error, reason} -> # Authorization denied
end
```

## Architecture

AriaAuth follows a layered architecture:

```
AriaAuth
├── Accounts (User Management)
├── Sessions (Session Lifecycle)
├── Macaroons (Authorization Tokens)
└── Repo (Data Persistence)
```

## Security Features

- **Password Hashing**: Secure password storage using Argon2
- **Session Security**: Cryptographically secure session tokens
- **Token Expiration**: Automatic cleanup of expired sessions
- **Capability-based Access**: Fine-grained authorization with macaroons
- **Database Security**: Prepared statements and input validation

## Configuration

Configure AriaAuth in your application:

```elixir
config :aria_auth, AriaAuth.Repo,
  database: "aria_auth_dev",
  hostname: "localhost",
  pool_size: 10

config :aria_auth,
  session_timeout: 3600,  # 1 hour
  macaroon_location: "aria-system"
```

## Development

### Running Tests

```bash
mix test test/aria_auth/ --timeout 120
```

### Database Setup

```bash
mix ecto.create
mix ecto.migrate
```

## Related Components

- **AriaEngine**: Core planning and execution engine
- **AriaSecurity**: Security infrastructure and secrets management
- **AriaStorage**: Persistent storage and archiving

## Status

AriaAuth provides stable authentication and session management. The macaroon-based authorization system enables flexible, secure access control for the Aria ecosystem.
