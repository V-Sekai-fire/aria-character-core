# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincExecutor.Native.Spec do
  use Unifex.Spec

  spec solve_raw(model_content :: string, options :: payload) ::
         {:ok, {status :: atom, solution :: payload, metadata :: payload}} |
         {:error, {error_type :: atom, details :: payload}}

  spec check_availability() ::
         {:ok, version :: string} |
         {:error, reason :: string}

  spec list_solvers() ::
         {:ok, solvers :: [string]} |
         {:error, reason :: string}
end
