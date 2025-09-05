-- TimescaleDB Optimization Script for the Bitemporal 6NF Schema
-- Version: 1.0
-- Date: 2025-09-04
--
-- This script should be run AFTER the 'bitemporal_6nf_postgres.sql' script.
-- It enables TimescaleDB's native compression on the bitemporal tables to
-- significantly reduce storage and improve query performance.

-- -----------------------------------------------------------------------------
-- Step 0: Ensure the TimescaleDB Extension is Active
-- -----------------------------------------------------------------------------
-- This command will create the extension if it doesn't already exist in the
-- database. It's safe to run even if it's already installed.

CREATE EXTENSION IF NOT EXISTS timescaledb;

-- -----------------------------------------------------------------------------
-- Step 1: Optimize the 'bitemporal_attributes' Table
-- -----------------------------------------------------------------------------

-- 1a. Convert the table to a TimescaleDB hypertable, partitioned by 'recorded_at'.
-- This is the most logical time dimension for partitioning as it represents
-- when the fact was added to the system. Chunks will be created for every 7 days.
SELECT create_hypertable('bitemporal_attributes', 'recorded_at', chunk_time_interval => INTERVAL '7 days');

-- 1b. Enable and configure compression.
-- We specify 'compress_orderby' to physically sort the data on disk by entity
-- and attribute. This groups related facts together and dramatically
-- improves compression ratios and query speed for lookups on specific entities.
ALTER TABLE bitemporal_attributes SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'entity_id, attribute_name'
);

-- 1c. Add a policy to automatically compress data chunks older than 1 month.
-- This keeps recent, frequently modified data uncompressed for faster writes,
-- while older, historical data is compressed for storage efficiency.
SELECT add_compress_chunks_policy('bitemporal_attributes', INTERVAL '1 month');

-- -----------------------------------------------------------------------------
-- Step 2: Optimize the 'bitemporal_structs' Table
-- -----------------------------------------------------------------------------

-- 2a. Convert the table to a hypertable, partitioned by 'recorded_at'.
SELECT create_hypertable('bitemporal_structs', 'recorded_at', chunk_time_interval => INTERVAL '7 days');

-- 2b. Enable and configure compression.
-- Here, we order by the entity the struct belongs to and the struct type.
ALTER TABLE bitemporal_structs SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'entity_id, struct_type'
);

-- 2c. Add a policy to automatically compress chunks older than 1 month.
SELECT add_compress_chunks_policy('bitemporal_structs', INTERVAL '1 month');

-- -----------------------------------------------------------------------------
-- Step 3: Optimize the 'bitemporal_relationships' Table
-- -----------------------------------------------------------------------------

-- 3a. Convert the table to a hypertable, partitioned by 'recorded_at'.
SELECT create_hypertable('bitemporal_relationships', 'recorded_at', chunk_time_interval => INTERVAL '7 days');

-- 3b. Enable and configure compression.
-- Ordering by relationship name and the primary entity optimizes lookups for
-- common relationship types.
ALTER TABLE bitemporal_relationships SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'relationship_name, entity_1_id'
);

-- 3c. Add a policy to automatically compress chunks older than 1 month.
SELECT add_compress_chunks_policy('bitemporal_relationships', INTERVAL '1 month');
