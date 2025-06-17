defmodule Mix.Tasks.AriaEngine.Benchmark.Satellite.DomainBuilder do
  @moduledoc "Builds the AriaEngine Domain for the Satellite benchmark."

  alias AriaEngine.Domain
  # Removed alias AriaEngine.PddlParser
  alias Mix.Tasks.AriaEngine.Benchmark.Satellite.DomainBuilder.Actions
  alias Mix.Tasks.AriaEngine.Benchmark.Satellite.DomainBuilder.Tasks
  alias Mix.Tasks.AriaEngine.Benchmark.Satellite.DomainBuilder.Methods

  @type parsed_domain_map :: AriaEngine.PddlParser.parsed_domain_map()
  @type initial_state :: AriaEngine.State.t()

  @spec build_aria_domain(parsed_domain_map(), initial_state()) :: Domain.t()
  def build_aria_domain(parsed_domain, initial_state) do
    domain = Domain.new(parsed_domain.name)

    domain = Actions.add_durative_actions(domain, parsed_domain, initial_state)
    domain = Tasks.add_tasks(domain, parsed_domain)
    domain = Methods.add_methods(domain, parsed_domain)

    domain
  end
end
