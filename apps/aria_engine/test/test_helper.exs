# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Start Ecto repositories for testing
Application.ensure_all_started(:aria_data)

# Setup database sandbox for concurrent testing
Ecto.Adapters.SQL.Sandbox.mode(AriaData.QueueRepo, :manual)

ExUnit.start()
