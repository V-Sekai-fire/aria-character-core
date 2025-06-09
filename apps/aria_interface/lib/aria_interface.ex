# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaInterface do
  @moduledoc """
  AriaInterface provides user interface and API capabilities.
  """

  @doc """
  Handle interface requests and return responses.
  """
  def handle_request(request, opts \\ []) do
    {:ok, %{request: request, response: opts, timestamp: DateTime.utc_now()}}
  end

  @doc """
  Health check for the interface service.
  """
  def health_check do
    {:ok, %{status: :healthy, service: :aria_interface}}
  end
end
