# Aria Bulk Data Persistence Service (Storage)

## Overview

The Bulk Data Persistence Service provides content-addressed storage for large, immutable assets including GLTF models, ONNX files, training datasets, and multimedia content with automatic deduplication and efficient delta sync capabilities.

## System Role

**Boot Order:** Core Services Layer (Boot Second)
**Dependencies:** `aria_security` (storage credentials), `aria_auth` (access authorization)
**External Systems:** aria_storage content-addressed system, optional golang desync client (verification only)

## Purpose

To act as the 'Archive Vault,' carefully preserving and organizing large treasures using smart chunking and deduplication, making efficient use of space while ensuring everything remains accessible.

## Key Responsibilities

- Store and retrieve large binary assets (GLTF, JSON, .scn, ONNX files) using content-addressed storage with SHA-256 CAIDs
- Provide chunk-level deduplication across different asset versions and types
- Enable efficient delta sync for asset updates and transfers
- Manage asset lifecycle including archival and cleanup of unused chunks
- Integrate with CDN for hot chunk distribution and cache invalidation
- Support multiple storage backends (SFTP, S3, local storage) for flexible deployment

## Core Technologies

- **desync**: Content-addressed storage implementation with casync compatibility
- **ExAws**: AWS S3 integration
- **SFTP**: Remote file storage support
- **Casync Native Compression**: Built-in compression optimized for chunk deduplication
- **Finch**: HTTP client for CDN sync

## Technology Choices

- **Desync for Storage**: This service will leverage Desync for chunk-based, content-addressed storage. This approach is chosen to optimize storage efficiency and data integrity, and it allows for fast, resumable transfers of bulk assets.
  - Desync version: v0.9.6
  - Download: <https://github.com/folbricht/desync/releases/download/v0.9.6/desync_0.9.6_linux_amd64.tar.gz>

## Service Type

Stateful

## Key Interactions

- **Security Service**: Obtains credentials for secure storage access
- **Authentication Service**: Validates service identity and authorization for asset operations
- **System Data Persistence Service**: Stores asset metadata and CAID references
- **Queue Service**: Uses Oban workers for background CDN sync and cleanup tasks
- **Character AI & Interpret Services**: Stores and retrieves ONNX models and training datasets
- **Interface Service**: Receives and stores incoming large assets