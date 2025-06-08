# Aria Security Service

## Overview

The Security Service manages, stores, and distributes sensitive data including secrets, certificates, and keys across the Aria Character Core system using OpenBao, an open source, community-driven fork of HashiCorp Vault managed by the Linux Foundation.

## Purpose

To act as the 'Guardian of Secrets,' carefully protecting and controlling access to sensitive information, ensuring that only authorized services and users can access what they need when they need it.

## Key Responsibilities

- Secure secret storage with encryption at rest for API keys, passwords, certificates, and other sensitive data
- Generate dynamic secrets on-demand for systems like Kubernetes or SQL databases with automatic revocation
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

## Service Type

Stateful (stores encrypted secrets, certificates, and access policies)

## Key Interactions

- **All Aria Services**: Provides secure credentials and certificates via OpenBao's native HTTP API
- **System Data Persistence Service**: For persistent backend storage of encrypted secret metadata
- **Coordinate Service**: For authentication and authorization of service requests
- **Kubernetes API**: For dynamic service account token generation and management
- **Monitor Service**: For security audit logging and access pattern analysis