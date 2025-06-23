defmodule AstMigrate.Rules.Behaviour do
  @moduledoc "Behaviour for AST transformation rules.\n\nThis behaviour defines the interface that all transformation rules must implement\nto be compatible with the AST migration tool.\n"
  @type file_path :: String.t()
  @type validation_function :: (file_path() -> boolean())
  @doc "Returns a human-readable description of what this rule does.\n"
  @callback description() :: String.t()
  @doc "Returns a list of file patterns that this rule applies to.\n\nUses glob patterns like [\"lib/**/*.ex\", \"test/**/*.exs\"]\n"
  @callback file_patterns() :: [String.t()]
  @doc "Returns a list of precondition validation functions.\n\nThese functions check if a file is eligible for transformation.\n"
  @callback preconditions() :: [validation_function()]
  @doc "Returns a list of postcondition validation functions.\n\nThese functions verify that the transformation was successful.\n"
  @callback postconditions() :: [validation_function()]
  @doc "Validates that all preconditions are met for the given files.\n"
  @callback validate_preconditions([file_path()]) :: :ok | {:error, String.t()}
  @doc "Transforms a single file according to this rule.\n\nReturns the transformed content or an error.\n"
  @callback transform_file(file_path()) :: {:ok, String.t()} | {:error, String.t()}
end