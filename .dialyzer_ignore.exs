[
  # Ignore warnings from dependencies
  ~r"deps/.+",
  # Ignore specific problematic files we can't control
  ~r"lib/aria_data/.+",
  ~r"lib/aria_auth/.+",
  ~r"lib/aria_storage/.+",
  ~r"lib/aria_security/.+",
  ~r"lib/aria_monitor/.+",
  ~r"lib/aria_workflow/.+",
  ~r"lib/aria_workflow_system/.+",
  ~r"lib/mix/tasks/.+",
  
  # Ignore callback info missing warnings
  {:warn_matching, :callback_info_missing},
  
  # Ignore unknown function warnings for dependencies we can't control
  {:warn_matching, :unknown_function},

  # Specific Logger warnings in AriaEngine
  {:error, "lib/aria_engine.ex:936:unknown_function"},
  {:error, "lib/aria_engine.ex:939:unknown_function"},
  {:error, "lib/aria_engine/actions.ex:99:unknown_function"},
  {:error, "lib/aria_engine/actions.ex:267:unknown_function"},
  {:error, "lib/aria_engine/actions.ex:316:unknown_function"},
  {:error, "lib/aria_engine/planner.ex:425:unknown_function"},
  {:error, "lib/aria_engine/planner.ex:513:unknown_function"},
  {:error, "lib/aria_engine/planner.ex:1160:unknown_function"},
  {:error, "lib/aria_engine/planner.ex:1230:unknown_function"},
  {:error, "lib/aria_engine/planner.ex:130:unknown_function"},
  {:error, "lib/aria_engine/planner.ex:1277:unknown_function"}
]
