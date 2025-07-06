# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Start the AriaJoint application to ensure the registry is available
{:ok, _} = Application.ensure_all_started(:aria_joint)

ExUnit.start()
