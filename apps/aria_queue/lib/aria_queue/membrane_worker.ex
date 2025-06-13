# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.MembraneWorker do
  @moduledoc """
  Membrane-based worker behavior that replaces Oban.Worker.

  Provides a similar interface to Oban.Worker but uses Membrane for processing.
  """

  @callback perform(job :: map()) :: :ok | {:error, term()}

  defmacro __using__(opts) do
    queue = Keyword.get(opts, :queue, :parallel_actions)
    max_attempts = Keyword.get(opts, :max_attempts, 3)

    quote do
      @behaviour AriaQueue.MembraneWorker

      def __queue__, do: unquote(queue)
      def __max_attempts__, do: unquote(max_attempts)
    end
  end
end
