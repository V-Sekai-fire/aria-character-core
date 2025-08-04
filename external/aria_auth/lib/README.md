# AriaAuth

**⚠️ ALPHA • Research Code • Not Production Ready ⚠️**

> **This module is part of the Aria Character Core research project. Most features are experimental, incomplete, or non-functional. See the root [README.md](../../README.md) for current project status and limitations.**

AriaAuth provides authentication and session management for the Aria Character Core system. It handles user accounts, secure sessions, and authorization using modern cryptographic techniques.

## Status

| Feature                | Status      | Notes                                      |
|------------------------|------------|--------------------------------------------|
| Account Management     | Partial    | Basic registration and login implemented   |
| Session Management     | Partial    | Sessions work, but may lack full security  |
| Macaroon Authorization | Experimental | API exists, not fully integrated/tested    |
| Database Integration   | Partial    | Persistence works, but not production-grade|

**Warning:** This module is not suitable for production use. Security features are experimental and may be incomplete or broken.

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

> **Note:** The following examples assume features are implemented. Some APIs may be incomplete or non-functional.

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

---

**Disclaimer:** Active research code. Expect incomplete features and non-functional systems. See the root [README.md](../../README.md) for current project status.
