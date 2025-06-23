# AriaSecurity Migration Tombstone

**Extracted:** 2025-06-23  
**New Location:** `apps/aria_security/`  
**ADR Reference:** ADR-151 Strict Encapsulation and Modular Testing Architecture

This module was extracted to maintain strict encapsulation boundaries.
All functionality now available in the dedicated umbrella app.

## What was moved

- `lib/aria_security/` → `apps/aria_security/lib/`
- `test/aria_security/` → `apps/aria_security/test/`

## Usage

The AriaSecurity module is now available as a separate umbrella app:

```elixir
# In your mix.exs dependencies
defp deps do
  [
    {:aria_security, path: "../aria_security"}
  ]
end

# Usage remains the same
{:ok, _status} = AriaSecurity.init(config)
{:ok, _} = AriaSecurity.write("secret/path", %{key: "value"})
{:ok, data} = AriaSecurity.read("secret/path")
```

## Modules extracted

- `AriaSecurity` - Main module with delegated functions
- `AriaSecurity.Application` - OTP application
- `AriaSecurity.Secrets` - Core secret management
- `AriaSecurity.OpenBao` - OpenBao server integration
- `AriaSecurity.SoftHSM` - Hardware security module support
- `AriaSecurity.SecretsMock` - Testing utilities
- `AriaSecurity.SecretsInterface` - Behavior definitions

## Testing

The module now has its own isolated test suite:

```bash
cd apps/aria_security && mix test
```

All tests pass independently without external dependencies.
