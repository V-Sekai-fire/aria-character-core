# ARCANA Format Specification

> **⚠️ PROTOTYPE STATUS WARNING**  
> ARCANA is currently in **prototype development** and is **NOT READY FOR PRODUCTION USE**.  
> The implementation is incomplete and may contain bugs. Use only for development and testing purposes.

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

## Implementation Constants

ARCANA uses specific constants from desync source code for binary compatibility:

- `CA_FORMAT_INDEX`: `0x96824d9c7b129ff9`
- `CA_FORMAT_TABLE`: `0xe75b9e112f17417d`
- `CA_FORMAT_TABLE_TAIL_MARKER`: `0x4b4f050e5549ecd1`
- `CA_FORMAT_ENTRY`: `0x1396fabcea5bbb51` (for CATAR format detection)

## CAIBX Format (Content Archive Index for Blobs)

Content Archive Index for Blobs files contain metadata and chunk references for blob content using the desync FormatIndex + FormatTable structure.

### Structure

```
CAIBX File:
┌─────────────────┬─────────────────┬─────────────────────┐
│ FormatIndex     │ FormatTable     │ Table Items + Tail  │
│ (48 bytes)      │ Header (16 bytes│ (variable)          │
└─────────────────┴─────────────────┴─────────────────────┘
```

### FormatIndex Header (48 bytes)

```
Offset | Size | Field           | Description
-------|------|-----------------|---------------------------
0      | 8    | size_field      | Always 48 (uint64)
8      | 8    | type_field      | CA_FORMAT_INDEX constant
16     | 8    | feature_flags   | Feature flags (uint64)
24     | 8    | chunk_size_min  | Minimum chunk size (uint64)
32     | 8    | chunk_size_avg  | Average chunk size (uint64)
40     | 8    | chunk_size_max  | Maximum chunk size (uint64)
```

### FormatTable Header (16 bytes)

```
Offset | Size | Field         | Description
-------|------|---------------|---------------------------
0      | 8    | table_marker  | Always 0xFFFFFFFFFFFFFFFF
8      | 8    | table_type    | CA_FORMAT_TABLE constant
```

### Table Item Format (40 bytes each)

```
Offset | Size | Field      | Description
-------|------|------------|---------------------------
0      | 8    | offset     | End offset of chunk (uint64)
8      | 32   | chunk_id   | SHA-256 hash of chunk data
```

### Table Tail Marker (40 bytes)

```
Offset | Size | Field         | Description
-------|------|---------------|---------------------------
0      | 8    | zero1         | Always 0
8      | 8    | zero2         | Always 0  
16     | 8    | size_field    | Always 48
24     | 8    | table_size    | Size of table data
32     | 8    | tail_marker   | CA_FORMAT_TABLE_TAIL_MARKER
```

## CAIDX Format (Content Archive Index)

Content Archive Index files reference CATAR archive chunks. Uses identical structure to CAIBX but with different magic detection and specialized for archive content.

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

Based on desync source code analysis, the primary compression algorithm is ZSTD:

```
Value | Algorithm        | Status
------|------------------|------------------
0     | None (raw)       | Standard
1     | ZSTD             | Primary/Standard
2-255 | Reserved         | Future use
```

**Note**: While the casync format theoretically supports multiple compression types, the desync implementation only uses ZSTD compression. ARCANA follows this practice for maximum compatibility.

## CATAR Format (Archive Container)

Archive container files store filesystem metadata and file content using a type-length-value (TLV) structure.

CATAR files can be detected in two ways:
1. **Magic-based detection**: Files starting with `0xCA 0x1A 0x52` magic bytes
2. **Structure-based detection**: Files starting with a 64-byte CA_FORMAT_ENTRY element

### Structure

```
CATAR File:
┌───────────────────────────────────────────────────────────┐
│ [Optional Magic: 0xCA 0x1A 0x52]                         │
│ Sequence of TLV Elements (variable length)               │
│ ┌─────────────┬─────────────┬───────────────────────────┐ │
│ │ Size (8)    │ Type (8)    │ Data (variable)           │ │
│ └─────────────┴─────────────┴───────────────────────────┘ │
└───────────────────────────────────────────────────────────┘
```

### TLV Element Header Format (16 bytes)

```
Offset | Size | Field         | Description
-------|------|---------------|---------------------------
0      | 8    | size          | Total size including header
8      | 8    | type          | Element type (CA_FORMAT_*)
```

### Entry Element Format (Variable length)

The CA_FORMAT_ENTRY element has variable length depending on UID/GID size:

```
Offset | Size | Field         | Description
-------|------|---------------|---------------------------
0      | 8    | size          | Total size including header
8      | 8    | type          | CA_FORMAT_ENTRY constant
16     | 8    | feature_flags | Feature flags for UID format
24     | 8    | mode          | Unix file mode/permissions
32     | 8    | field5        | Reserved field
40     | 2-8  | gid           | Group ID (16/32/64-bit)
42-48  | 2-8  | uid           | User ID (16/32/64-bit)
44-56  | 8    | mtime         | Modification time (Unix timestamp)
```

### Element Types

Based on CA_FORMAT_* constants:

```
Constant                | Value               | Description
------------------------|---------------------|---------------------------
CA_FORMAT_ENTRY         | 0x1396fabcea5bbb51  | File/directory entry
CA_FORMAT_FILENAME      | 0x6dbb6ebcb3161f0b  | Filename string
CA_FORMAT_PAYLOAD       | 0x8b9e1d93d6dcffc9  | File content data
CA_FORMAT_SYMLINK       | 0x664a6fb6830e0d6c  | Symbolic link target
CA_FORMAT_DEVICE        | 0xac3dace369dfe643  | Device major/minor
CA_FORMAT_USER          | 0xf453131aaeeaccb3  | User name string
CA_FORMAT_GROUP         | 0x25eb6ac969396a52  | Group name string
CA_FORMAT_SELINUX       | 0x46faf0602fd26c59  | SELinux context
CA_FORMAT_GOODBYE       | 0xdfd35c5e8327c403  | Directory end marker
```

## Implementation Notes

### Parser Architecture

ARCANA uses **direct binary pattern matching** for robust parsing of the structured binary formats. This approach provides:

- **Performance**: Direct binary pattern matching without parser overhead
- **Reliability**: Avoids UTF-8 encoding issues with binary data
- **Maintainability**: Clear and readable binary parsing logic
- **Error handling**: Detailed error reporting with context information
- **Binary precision**: Exact byte-level control over parsing

### Binary Pattern Matching

The binary format is parsed using direct Elixir binary pattern matching:

```elixir
# FormatIndex structure parsing (48 bytes total)
<<size_field::little-64, type_field::little-64, feature_flags::little-64,
  chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64,
  remaining_data::binary>>

# FormatTable header parsing (16 bytes)
<<table_marker::little-64, table_type::little-64, remaining_data::binary>>

# Table Item parsing (40 bytes each)
<<item_offset::little-64, chunk_id::binary-size(32), remaining_data::binary>>

# CACNK header parsing (3-byte magic + 16-byte header)
<<0xCA, 0xC4, 0x4E, compressed_size::little-32, uncompressed_size::little-32,
  compression_type::little-32, flags::little-32, remaining_data::binary>>

# CATAR format detection (two methods)
<<0xCA, 0x1A, 0x52, _::binary>>  # Magic-based detection
<<64::little-64, @ca_format_entry::little-64, _::binary>>  # Structure-based detection
```

**Note**: Some constants and magic numbers are commented out in the implementation to avoid compiler warnings about unused constants. These are reserved for future implementation or format detection features.

### Desync Compatibility Constants

ARCANA uses the exact constants from the desync source code to ensure perfect binary compatibility:

```elixir
@ca_format_index 0x96824d9c7b129ff9
@ca_format_table 0xe75b9e112f17417d  
@ca_format_table_tail_marker 0x4b4f050e5549ecd1
```

These constants are embedded in the binary format headers rather than using simple magic bytes, following the desync approach exactly.

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

The reference implementation is available in the AriaStorage module of the Aria Character Core project, written in Elixir.

---

**Document Version**: 1.0  
**Last Updated**: June 11, 2025  
**License**: MIT License  
**Specification Maintainer**: Aria Character Core Project
