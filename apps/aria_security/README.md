# Aria Security Service

## Overview

The Security Service manages, stores, and distributes sensitive data including secrets, certificates, and keys across the Aria Character Core system using OpenBao, an open source, community-driven fork of HashiCorp Vault managed by the Linux Foundation.

## Purpose

To act as the 'Guardian of Secrets,' carefully protecting and controlling access to sensitive information, ensuring that only authorized services and users can access what they need when they need it.

## Key Responsibilities

- Secure secret storage with encryption at rest for API keys, passwords, certificates, and other sensitive data
- Generate dynamic secrets on-demand for systems like system orchestration platforms or SQL databases with automatic revocation
- Provide encryption as a service with centralized key management for data in transit and at rest
- Manage identity-based access control with unified ACL system across different clouds and services
- Handle secret leasing, renewal, and revocation with built-in lifecycle management
- Integrate with the System Data Persistence Service for persistent backend while maintaining security isolation
- Operate securely through OpenBao's native HTTP API with built-in TLS encryption

## Core Technologies

- **OpenBao**: Open source secrets management and encryption platform
- **HTTPoison/Req**: Elixir HTTP client libraries for OpenBao API integration
- **PKI**: Public Key Infrastructure for certificate management
- **Transit encryption engines**: For encryption as a service

## Technology Choices

- **Bundled OpenBao**: This service bundles OpenBao directly for integrated secrets management. This approach simplifies deployment and enhances security by keeping secrets management self-contained within the service's operational boundary.
  - OpenBao version: v2.2.2
  - Download: <https://github.com/openbao/openbao/releases/download/v2.2.2/bao-hsm_2.2.2_linux_amd64.deb>

## Service Type

Stateful (stores encrypted secrets, certificates, and access policies)

## Key Interactions

- **All Aria Services**: Provides secure credentials and certificates via OpenBao's native HTTP API
- **System Data Persistence Service**: For persistent backend storage of encrypted secret metadata
- **Coordinate Service**: For authentication and authorization of service requests
- **Monitor Service**: For security audit logging and access pattern analysis

## Setup and Local Development

To run OpenBao locally for development and testing of the `aria_security` service:

1.  **Download the OpenBao .deb package:**
    ```bash
    wget https://github.com/openbao/openbao/releases/download/v2.2.2/bao-hsm_2.2.2_linux_amd64.deb
    ```
2.  **Extract the OpenBao binary:**
    Create a temporary directory and extract the .deb contents:
    ```bash
    mkdir ./openbao_files
    dpkg -x bao-hsm_2.2.2_linux_amd64.deb ./openbao_files
    ```
    The `bao` binary will likely be in `openbao_files/usr/bin/bao` or `openbao_files/usr/local/bin/bao`.
3.  **Place the `bao` binary:**
    Create a `priv/bin` directory within this app (`apps/aria_security/priv/bin`) if it doesn't exist, and copy the `bao` binary there.
    ```bash
    mkdir -p apps/aria_security/priv/bin
    cp ./openbao_files/usr/bin/bao apps/aria_security/priv/bin/ # Adjust path if necessary
    rm -rf ./openbao_files bao-hsm_2.2.2_linux_amd64.deb # Clean up
    ```
    Ensure the binary is executable:
    ```bash
    chmod +x apps/aria_security/priv/bin/bao
    ```
4.  **Supervision:**
    The `AriaSecurity.Application` module is responsible for starting and supervising the OpenBao server process using `Porcelain.Supervisor`. The `mix.exs` file has been updated to include `{:porcelain, "~> 2.0"}` for this purpose. You will need to implement the supervision logic in `lib/aria_security/application.ex`.

    The OpenBao server will be configured to run in "dev" mode for local development, which is convenient but **not suitable for production**.
