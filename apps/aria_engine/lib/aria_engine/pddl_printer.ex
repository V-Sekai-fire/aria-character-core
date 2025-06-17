defmodule AriaEngine.PddlPrinter do
  @moduledoc """
  Provides functions for pretty printing PDDL/HDDL structures.
  """
  alias AriaEngine.Pddl.Domain
  alias AriaEngine.Pddl.Problem
  alias AriaEngine.PddlPrinter.DomainPrinter
  alias AriaEngine.PddlPrinter.ProblemPrinter

  @doc """
  Formats a PDDL structure based on its type (:domain or :problem).
  """
  @spec format(:domain, Domain.t()) :: String.t()
  @spec format(:problem, Problem.t()) :: String.t()
  def format(:domain, parsed_domain), do: DomainPrinter.format_domain(parsed_domain)
  def format(:problem, parsed_problem), do: ProblemPrinter.format_problem(parsed_problem)
  def format(type, _parsed_structure), do: raise(ArgumentError, "Unknown PDDL type for printing: #{type}")

  @doc """
  Formats a PDDL domain struct into a human-readable string.
  """
  @spec format_domain(Domain.t()) :: String.t()
  def format_domain(parsed_domain) do
    DomainPrinter.format_domain(parsed_domain)
  end

  @doc """
  Formats a PDDL problem struct into a human-readable string.
  """
  @spec format_problem(Problem.t()) :: String.t()
  def format_problem(parsed_problem) do
    ProblemPrinter.format_problem(parsed_problem)
  end
end
