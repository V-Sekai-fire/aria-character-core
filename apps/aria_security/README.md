# Aria Security Service

## Overview

The Security Service manages, stores, and distributes sensitive data including secrets, certificates, and keys across the Aria Character Core system using an Ecto/SQLite backend with `Ecto.Cloak` for encryption at rest.

## Purpose

To act as the 'Guardian of Secrets,' carefully protecting and controlling access to sensitive information, ensuring that only authorized services and users can access what they need when they need it.

## Key Responsibilities

- Secure secret storage with encryption at rest for API keys, passwords, certificates, and other sensitive data.
- Provide cryptographic operations (e.g., key generation, signing, verification) using `ex_crypto` and potentially hardware security modules (HSM) like SoftHSM.
- Manage identity-based access control (details to be implemented).
- Handle secret lifecycle management (details to be implemented).
- Integrate with the System Data Persistence Service for persistent backend while maintaining security isolation.

## Core Technologies

- **Ecto**: Elixir's database wrapper and language integrated query.
- **SQLite**: Lightweight, file-based database for secret storage.
- **Ecto.Cloak**: Library for transparent encryption of Ecto fields.
- **ex_crypto**: Elixir cryptographic library, potentially integrating with PKCS#11 for HSMs.

## Service Type

Stateful (stores encrypted secrets, certificates, and access policies).

## Key Interactions

- **All Aria Services**: Provides secure credentials and certificates via its API.
- **System Data Persistence Service**: For persistent backend storage of encrypted secret metadata.
- **Coordinate Service**: For authentication and authorization of service requests.
- **Monitor Service**: For security audit logging and access pattern analysis.

## Setup and Local Development

To set up the `aria_security` service locally:

1.  **Database Migration:** Ensure your Ecto migrations are run to create the `secrets` table.
    ```bash
    mix ecto.migrate -r AriaSecurity.SecretsRepo
    ```
2.  **Configuration:** Ensure `Ecto.Cloak` is configured with a valid encryption key in your `config/*.exs` files.
    ```elixir
    config :aria_security, Ecto.Cloak,
      cipher: {Ecto.Cloak.Ciphers.AES256GCM, tag: "AriaSecurity", key: "your-super-secret-key-of-32-bytes-"}
    ```
    **Note:** For production, the encryption key should be managed securely (e.g., via environment variables).

3.  **Cryptographic Operations (Optional, if using SoftHSM/PKCS#11):**
    If you intend to use SoftHSM or other PKCS#11 devices with `ex_crypto`, you will need to install and configure them separately. Refer to the `ex_crypto` documentation for details.
