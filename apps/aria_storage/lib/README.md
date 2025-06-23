# AriaStorage

AriaStorage provides efficient content-addressable storage and archiving capabilities for the Aria Character Core system. It implements chunked storage, deduplication, and compression for optimal data management.

## Overview

AriaStorage implements a modern storage system with:

- **Content-Addressable Storage**: Files identified by cryptographic hashes
- **Chunked Storage**: Large files split into manageable chunks for efficiency
- **Deduplication**: Automatic elimination of duplicate data
- **Compression**: Efficient storage using casync-compatible formats
- **Archive Management**: Long-term storage and retrieval capabilities

## Core Components

### File Management

- `AriaStorage.Files` - High-level file operations and metadata management
- `AriaStorage.File` - Individual file representation and operations
- `AriaStorage.FileRecord` - Database persistence for file metadata

### Chunked Storage

- `AriaStorage.Chunks` - Chunk creation, storage, and retrieval
- `AriaStorage.ChunkStore` - Low-level chunk storage backend
- `AriaStorage.ChunkUploader` - Efficient chunk upload and synchronization

### Archive System

- `AriaStorage.Archives` - Archive creation and management
- `AriaStorage.CasyncDecoder` - Casync-compatible archive decoding
- Support for `.caibx` (casync index) and `.caidx` (casync data) formats

## Usage

### File Storage

```elixir
# Store a file with automatic chunking
{:ok, file_record} = AriaStorage.Files.store_file("/path/to/file.txt")

# Retrieve file metadata
{:ok, file} = AriaStorage.Files.get_file(file_record.id)

# Download file content
{:ok, content} = AriaStorage.Files.download_file(file_record.id)
```

### Chunk Operations

```elixir
# Create chunks from data
chunks = AriaStorage.Chunks.create_chunks(data, chunk_size: 64_000)

# Store chunks
Enum.each(chunks, fn chunk ->
  AriaStorage.ChunkStore.store_chunk(chunk.hash, chunk.data)
end)

# Retrieve chunk
{:ok, chunk_data} = AriaStorage.ChunkStore.get_chunk(chunk_hash)
```

### Archive Management

```elixir
# Create archive from files
{:ok, archive} = AriaStorage.Archives.create_archive([
  "/path/to/file1.txt",
  "/path/to/file2.txt"
])

# Extract archive
{:ok, extracted_files} = AriaStorage.Archives.extract_archive(archive_path)

# Decode casync archive
{:ok, decoded_data} = AriaStorage.CasyncDecoder.decode_file(
  "archive.caibx",
  chunk_directory: "/chunks"
)
```

## Architecture

AriaStorage follows a layered architecture:

```
AriaStorage
├── Files (High-level Operations)
├── Chunks (Content-Addressable Storage)
├── Archives (Compression & Packaging)
└── Storage Backend (Persistence Layer)
```

## Storage Features

- **Content Deduplication**: Identical chunks stored only once
- **Incremental Backup**: Only changed chunks need to be transferred
- **Parallel Processing**: Concurrent chunk operations for performance
- **Integrity Verification**: Cryptographic hash verification
- **Compression**: Efficient storage using modern compression algorithms

## Configuration

Configure AriaStorage in your application:

```elixir
config :aria_storage,
  chunk_size: 64_000,
  storage_backend: AriaStorage.ChunkStore.FileSystem,
  storage_path: "/var/lib/aria/storage",
  compression: :zstd
```

## Storage Backends

AriaStorage supports multiple storage backends:

- **FileSystem**: Local filesystem storage (default)
- **S3**: Amazon S3 compatible storage
- **Memory**: In-memory storage for testing

## Development

### Running Tests

```bash
mix test test/aria_storage/ --timeout 120
```

### Storage Cleanup

```bash
# Clean up orphaned chunks
AriaStorage.Chunks.cleanup_orphaned_chunks()

# Verify storage integrity
AriaStorage.Files.verify_integrity()
```

## Performance

AriaStorage is optimized for:

- **Large Files**: Efficient handling of multi-gigabyte files
- **High Throughput**: Parallel chunk processing
- **Low Latency**: Fast retrieval of frequently accessed data
- **Storage Efficiency**: Deduplication and compression reduce storage requirements

## Use Cases

- **Game Asset Storage**: Efficient storage of textures, models, and audio
- **Version Control**: Content-addressable storage for file versioning
- **Backup Systems**: Incremental backup with deduplication
- **Content Distribution**: Efficient distribution of large files

## Related Components

- **AriaEngine**: Core planning and execution engine
- **AriaAuth**: Authentication and session management
- **AriaSecurity**: Security infrastructure and secrets management

## Status

AriaStorage provides stable content-addressable storage with ongoing optimization for performance and storage efficiency. The casync-compatible format ensures interoperability with existing tools.
