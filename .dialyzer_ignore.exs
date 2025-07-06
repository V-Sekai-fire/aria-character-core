# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

[
  # Ignore warnings from dependencies
  ~r"deps/.+",
  # Ignore specific problematic files we can't control
  ~r"lib/aria_data/.+",
  ~r"lib/aria_auth/.+",
  ~r"lib/aria_storage/.+",
  ~r"lib/aria_security/.+",
  ~r"lib/aria_monitor/.+",
  ~r"lib/mix/tasks/.+",

  # Ignore callback info missing warnings
  {:warn_matching, :callback_info_missing},

  # Ignore generic unknown function warnings for dependencies we can't control
  {:warn_matching, :unknown_function},

  # Specific Logger warnings (false positives)
  ~r"Function Logger.__do_log__/4 does not exist.",
  ~r"Function Logger.__should_log__/2 does not exist.",
  ~r"Function Logger.configure/1 does not exist.",

  # Specific Porcelain warnings (false positives after adding dependency)
  ~r"Function Porcelain.shell/2 does not exist.",
  ~r"Function Porcelain.exec/3 does not exist."
]
