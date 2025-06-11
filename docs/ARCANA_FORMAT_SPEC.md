# ARCANA Format Specification

**ARCANA** (Aria Content Archive and Network Architecture) is a **fully compatible implementation** of the casync binary format specification. ARCANA maintains perfect binary compatibility with casync/desync tools while providing enhanced features for distributed storage and content delivery.

## Version

This document describes ARCANA Format Specification version 1.0, which implements casync format compatibility.

## Overview

ARCANA implements the four casync binary formats with **identical** magic numbers, structures, and behaviors:

1. **CAIBX** (`.caibx`) - Content Archive Index for Blobs
2. **CAIDX** (`.caidx`) - Content Archive Index for Directories
3. **CACNK** (`.cacnk`) - Content Archive Chunks
4. **CATAR** (`.catar`) - Content Archive Tar-like format

## Magic Numbers

ARCANA uses the **exact same** 3-byte magic numbers as casync:

- **CAIBX**: `0xCA 0x1B 0x5C` (202, 27, 92)
- **CAIDX**: `0xCA 0x1D 0x5C` (202, 29, 92)
- **CACNK**: `0xCA 0xC4 0x4E` (202, 196, 78)
- **CATAR**: `0xCA 0x1A 0x52` (202, 26, 82)

These magic numbers are **never changed** to ensure perfect compatibility with existing casync/desync tools.

## Data Types

All multi-byte integers are stored in little-endian format unless otherwise specified.

- `uint32` - 32-bit unsigned integer (4 bytes)
- `uint64` - 64-bit unsigned integer (8 bytes)
- `hash256` - 256-bit hash digest (32 bytes)
- `blob` - Variable-length binary data

## CAIBX Format (Content Archive Index for Blobs)

Content Archive Index for Blobs files contain metadata and chunk references for blob content.

### Structure

```
CAIBX File:
┌─────────────────┬──────────────────┬─────────────────────┐
│ Magic (3 bytes) │ Header (20 bytes)│ Chunk Entries (var) │
└─────────────────┴──────────────────┴─────────────────────┘
```

### Header Format

```
Offset | Size | Field        | Description
-------|------|--------------|---------------------------
0      | 4    | version      | Format version (uint32)
4      | 8    | total_size   | Total content size (uint64)
12     | 4    | chunk_count  | Number of chunks (uint32)
16     | 4    | reserved     | Reserved for future use
```

### Chunk Entry Format

Each chunk entry is 48 bytes:

```
Offset | Size | Field      | Description
-------|------|------------|---------------------------
0      | 32   | chunk_id   | SHA-256 hash of chunk data
32     | 8    | offset     | Offset in original content
40     | 4    | size       | Size of chunk in bytes
44     | 4    | flags      | Chunk flags (see below)
```

### Chunk Flags

```
Bit | Description
----|------------------
0   | Compressed chunk
1   | Encrypted chunk
2   | Sparse chunk
3   | Deduplicated
4-31| Reserved
```

## CAIDX Format (Content Archive Index)

Content Archive Index files reference CATAR archive chunks.

### Structure

Similar to CAIBX but with different magic number (`0xCA 0x1D 0x5C`) and specialized for archive content.

## CACNK Format (Compressed Chunk)

Individual chunk files containing compressed or raw chunk data.

### Structure

```
CACNK File:
┌─────────────────┬──────────────────┬─────────────────┐
│ Magic (3 bytes) │ Header (16 bytes)│ Data (variable) │
└─────────────────┴──────────────────┴─────────────────┘
```

### Header Format

```
Offset | Size | Field              | Description
-------|------|--------------------|---------------------------
0      | 4    | compressed_size    | Size of compressed data
4      | 4    | uncompressed_size  | Size when decompressed
8      | 4    | compression_type   | Compression algorithm
12     | 4    | flags              | Chunk flags
```

### Compression Types

```
Value | Algorithm
------|----------
0     | None (raw)
1     | ZSTD
2     | XZ/LZMA2
3     | GZIP
4     | LZ4
5     | BROTLI
6-255 | Reserved
```

## CATAR Format (Archive Container)

Archive container files store filesystem metadata and file content.

### Structure

```
CATAR File:
┌─────────────────┬─────────────────────────────────────┐
│ Magic (3 bytes) │ Archive Entries (variable length)   │
└─────────────────┴─────────────────────────────────────┘
```

### Entry Structure

Each entry contains a header followed by metadata and optional content:

```
Entry:
┌─────────────────┬─────────────────┬─────────────────┐
│ Entry Header    │ Entry Metadata  │ Entry Content   │
│ (32 bytes)      │ (32 bytes)      │ (variable)      │
└─────────────────┴─────────────────┴─────────────────┘
```

### Entry Header Format

```
Offset | Size | Field         | Description
-------|------|---------------|---------------------------
0      | 8    | entry_size    | Total size of this entry
8      | 8    | entry_type    | Type of filesystem object
16     | 8    | entry_flags   | Entry-specific flags
24     | 8    | padding       | Reserved padding
```

### Entry Types

```
Value | Type
------|----------
0     | Unknown
1     | Regular file
2     | Directory
3     | Symbolic link
4     | Block device
5     | Character device
6     | FIFO
7     | Socket
8-255 | Reserved
```

### Entry Metadata Format

```
Offset | Size | Field  | Description
-------|------|--------|---------------------------
0      | 8    | mode   | Unix file mode/permissions
8      | 8    | uid    | User ID
16     | 8    | gid    | Group ID
24     | 8    | mtime  | Modification time (Unix timestamp)
```

## Implementation Notes

### Endianness

All multi-byte integers MUST be stored in little-endian byte order.

### Alignment

Data structures are naturally aligned but not padded beyond specified sizes.

### Hash Algorithm

- Primary hash: SHA-256 (32 bytes)
- Alternative: BLAKE3 (32 bytes) - when flags indicate

### Compression

Default compression algorithm is ZSTD with adaptive compression levels based on content type detection.

### Version Compatibility

- Version 1.x: Forward compatible within major version
- Implementations MUST reject files with unsupported major versions
- Implementations SHOULD handle unknown minor version features gracefully

## Security Considerations

### Content Verification

- All chunk IDs MUST be verified against actual content hashes
- Implementations SHOULD validate chunk sizes against headers
- Archive metadata SHOULD be validated for consistency

### Access Control

- Archive entries preserve Unix permission bits
- Implementations MUST respect security boundaries when extracting
- Symbolic links MUST be validated for path traversal attacks

## Performance Characteristics

### Chunking Strategy

- Default chunk size: 64KB for small files, adaptive for large files
- Minimum chunk size: 4KB
- Maximum chunk size: 16MB
- Rolling hash algorithm: Buzhash with 64KB window

### Deduplication

- Content-addressed chunks enable automatic deduplication
- Cross-archive deduplication when using same chunking parameters
- Sparse file detection and optimization

## File Extensions

ARCANA uses the **exact same** file extensions as casync:

- `.caibx` - Content Archive Index for Blobs
- `.caidx` - Content Archive Index for Directories  
- `.cacnk` - Compressed Chunk files
- `.catar` - Archive Container files

## MIME Types

- `application/x-casync-index` - For .caibx and .caidx files
- `application/x-casync-chunk` - For .cacnk files  
- `application/x-casync-archive` - For .catar files

## Compatibility

ARCANA formats are designed to be **fully binary compatible** with:

- casync/desync tools (identical magic numbers and structure)
- Content-addressable storage systems
- CDN and distributed storage networks
- Backup and synchronization tools

Files created with ARCANA tools can be read by standard casync/desync implementations and vice versa.

## Reference Implementation

The reference implementation is available in the AriaStorage module of the Aria Character Core project, written in Elixir with ABNF parsing support.

## Future Extensions

### Planned Features

- Multi-hash support (BLAKE3, SHA-3)
- Advanced compression algorithms
- Encryption at rest
- Distributed storage metadata
- Incremental synchronization optimization

### Reserved Fields

All reserved fields and flag bits are reserved for future specification versions and MUST be set to zero in version 1.0 implementations.

---

**Document Version**: 1.0  
**Last Updated**: June 11, 2025  
**License**: MIT License  
**Specification Maintainer**: Aria Character Core Project
