# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrikeWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use AriaTimestrikeWeb, :controller` and
  `use AriaTimestrikeWeb, :live_view`.
  """
  use AriaTimestrikeWeb, :html

  def get_csrf_token do
    Plug.CSRFProtection.get_csrf_token()
  end

  embed_templates "layouts/*"
end
