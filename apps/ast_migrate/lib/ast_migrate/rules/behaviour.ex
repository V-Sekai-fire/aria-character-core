# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.Behaviour do
  @moduledoc """
  Behaviour for AST transformation rules.

  This behaviour defines the interface that all transformation rules must implement
  to be compatible with the AST migration tool.
  """

  @type file_path :: String.t()
  @type validation_function :: (file_path() -> boolean())

  @doc "Returns a human-readable description of what this rule does."
  @callback description() :: String.t()

  @doc """
  Returns a list of file patterns that this rule applies to.

  Uses glob patterns like ["lib/**/*.ex", "test/**/*.exs"]
  """
  @callback file_patterns() :: [String.t()]

  @doc """
  Returns a list of precondition validation functions.

  These functions check if a file is eligible for transformation.
  """
  @callback preconditions() :: [validation_function()]

  @doc """
  Returns a list of postcondition validation functions.

  These functions verify that the transformation was successful.
  """
  @callback postconditions() :: [validation_function()]

  @doc "Validates that all preconditions are met for the given files."
  @callback validate_preconditions([file_path()]) :: :ok | {:error, String.t()}

  @doc """
  Transforms a single file according to this rule.

  Returns the transformed content or an error.
  """
  @callback transform_file(file_path()) :: {:ok, String.t()} | {:error, String.t()}
end
