# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
