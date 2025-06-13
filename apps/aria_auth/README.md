# Aria Authentication Service

## Overview

The Authentication Service provides centralized identity verification, session management, and role-based access control (RBAC) for all Aria Character Core services and users, enforcing zero trust principles where every request must be authenticated and authorized.

## System Role

**Boot Order:** Core Services Layer (Boot Second)
**Dependencies:** `aria_security` (secrets/certs), `aria_data` (user/token storage)
**External Systems:** OAuth2 providers, WebRTC STUN/TURN servers

## Purpose

To act as the 'Identity Gatekeeper,' ensuring that every entity in the system proves who they are and what they're allowed to do, maintaining trust through continuous verification.

## Key Responsibilities

- Authenticate users and services using native Elixir authentication mechanisms and WebRTC for real-time identity verification
- Manage user sessions with secure token generation, validation, and revocation using Elixir-native session management
- Implement role-based access control (RBAC) and attribute-based access control (ABAC) policies
- Provide identity federation and integration with external identity providers via Elixir OAuth2/OIDC implementations
- Handle multi-factor authentication (MFA) and adaptive authentication policies with WebRTC-based verification channels
- Maintain audit logs of all authentication and authorization events
- Support zero trust principles with continuous identity verification

## Core Technologies

- **Guardian**: Elixir authentication library
- **Joken**: JWT handling for Elixir
- **BCrypt**: Password hashing
- **OAuth2/OIDC**: Identity federation protocols
- **WebRTC**: Real-time communication and identity verification
- **HTTPoison/Req**: HTTP client for external identity providers

## Service Type

Stateful (stores user sessions, identity mappings, and access policies)

## Key Interactions

- **Security Service**: Obtains encryption keys and certificates for secure token signing
- **System Data Persistence Service**: Persists user profiles, roles, and access policies
- **All Aria Services**: Provides authentication tokens and validates authorization for every request
- **Monitor Service**: Sends authentication events and security audit logs
- **External Identity Providers**: Federates with corporate SSO, LDAP, or social login providers