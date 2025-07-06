# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AstMigrate.Rules.Behaviour do
  @moduledoc """
  Behaviour for AST migration rules.

  This behaviour defines the interface that all AST migration rules must implement.
  Rules are responsible for transforming Elixir source code to fix specific issues
  or apply specific migrations.
  """

  @doc "Returns a human-readable description of what this rule does."
  @callback description() :: String.t()

  @doc "Returns a list of file patterns that this rule should be applied to."
  @callback file_patterns() :: [String.t()]

  @doc "Returns a list of precondition functions for file eligibility."
  @callback preconditions() :: [(String.t() -> boolean())]

  @doc "Returns a list of postcondition functions for transformation verification."
  @callback postconditions() :: [(String.t() -> boolean())]

  @doc "Validates that the given files meet the preconditions for this rule."
  @callback validate_preconditions([String.t()]) :: :ok | {:error, String.t()}

  @doc "Transforms a single file according to this rule."
  @callback transform_file(String.t()) :: {:ok, String.t()} | {:error, String.t()}
end
