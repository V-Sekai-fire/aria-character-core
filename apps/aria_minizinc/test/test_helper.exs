# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Load mock definitions
Code.require_file("support/mocks/solver_behaviour.ex", __DIR__)
Code.require_file("support/mocks/executor_behaviour.ex", __DIR__)

# Configure Mox
Mox.defmock(AriaMiniZinc.MockSolver, for: AriaMiniZinc.SolverBehaviour)
Mox.defmock(AriaMiniZinc.MockExecutor, for: AriaMiniZinc.ExecutorBehaviour)

# Force all tests to use mock solver by default
Application.put_env(:aria_minizinc, :default_solver_type, :test)

# Configure test environment to use mocks
ExUnit.start()

# Set up global test configuration
ExUnit.configure(exclude: [:external_dependency])
