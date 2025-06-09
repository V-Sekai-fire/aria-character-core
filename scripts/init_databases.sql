-- Copyright (c) 2025-present K. S. Ernest (iFire) Lee
-- SPDX-License-Identifier: MIT

-- CockroachDB Database Initialization Script
-- This script creates all databases needed for the aria-character-core umbrella project

-- Development databases
CREATE DATABASE IF NOT EXISTS aria_data_dev;
CREATE DATABASE IF NOT EXISTS aria_auth_dev;
CREATE DATABASE IF NOT EXISTS aria_queue_dev;
CREATE DATABASE IF NOT EXISTS aria_storage_dev;
CREATE DATABASE IF NOT EXISTS aria_monitor_dev;
CREATE DATABASE IF NOT EXISTS aria_engine_dev;

-- Test databases
CREATE DATABASE IF NOT EXISTS aria_data_test;
CREATE DATABASE IF NOT EXISTS aria_auth_test;
CREATE DATABASE IF NOT EXISTS aria_queue_test;
CREATE DATABASE IF NOT EXISTS aria_storage_test;
CREATE DATABASE IF NOT EXISTS aria_monitor_test;
CREATE DATABASE IF NOT EXISTS aria_engine_test;

-- Production databases (typically created separately in production)
CREATE DATABASE IF NOT EXISTS aria_data_prod;
CREATE DATABASE IF NOT EXISTS aria_auth_prod;
CREATE DATABASE IF NOT EXISTS aria_queue_prod;
CREATE DATABASE IF NOT EXISTS aria_storage_prod;
CREATE DATABASE IF NOT EXISTS aria_monitor_prod;
CREATE DATABASE IF NOT EXISTS aria_engine_prod;

-- Show created databases
SHOW DATABASES;
