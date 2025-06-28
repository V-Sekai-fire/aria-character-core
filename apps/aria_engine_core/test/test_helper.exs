# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Configure Mox for dependency injection testing
Mox.defmock(AriaEngineCore.Mocks.PlannerMock,
  for: AriaEngineCore.Behaviours.PlannerBehaviour)

ExUnit.start()
