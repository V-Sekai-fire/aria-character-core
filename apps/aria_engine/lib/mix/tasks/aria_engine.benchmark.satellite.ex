defmodule Mix.Tasks.AriaEngine.Benchmark.Satellite do
  @moduledoc "Benchmarks the Satellite HDDL SAT problem."
  use Mix.Task

  alias Mix.Tasks.AriaEngine.Benchmark.Satellite.Core
  # Removed alias Mix.Tasks.AriaEngine.Benchmark.Satellite.DomainBuilder
  # Removed alias Mix.Tasks.AriaEngine.Benchmark.Satellite.StateBuilder

  @shortdoc "Benchmarks the Satellite HDDL SAT problem"
  def run(_) do
    Core.run()
  end
end
