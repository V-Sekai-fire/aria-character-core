defmodule Mix.Tasks.AriaEngine.Benchmark.Satellite.DomainBuilder.Tasks do
  @moduledoc "Handles adding tasks to the AriaEngine Domain."

  # Removed alias AriaEngine.PddlParser

  @type parsed_domain_map :: AriaEngine.PddlParser.parsed_domain_map()

  @spec add_tasks(AriaEngine.Domain.Core.t(), parsed_domain_map()) :: AriaEngine.Domain.Core.t()
  def add_tasks(domain, parsed_domain) do
    Enum.reduce(parsed_domain.tasks, domain, fn _task, acc_domain ->
      # For tasks, we just need to ensure they are recognized.
      # Their decomposition is handled by methods.
      acc_domain
    end)
  end
end
