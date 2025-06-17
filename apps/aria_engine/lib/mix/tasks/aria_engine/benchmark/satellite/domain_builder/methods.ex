defmodule Mix.Tasks.AriaEngine.Benchmark.Satellite.DomainBuilder.Methods do
  @moduledoc "Handles adding methods to the AriaEngine Domain."

  alias AriaEngine.Domain
  alias AriaEngine.SatelliteMethods
  # Removed alias AriaEngine.PddlParser

  @type parsed_domain_map :: AriaEngine.PddlParser.parsed_domain_map()

  @spec add_methods(Domain.t(), parsed_domain_map()) :: Domain.t()
  def add_methods(domain, parsed_domain) do
    Enum.reduce(parsed_domain.methods, domain, fn method, acc_domain ->
      method_fn = case method.name do
        :method0 -> fn _state, args -> SatelliteMethods.method0(args) end
        :method1 -> fn _state, args -> SatelliteMethods.method1(args) end
        :method2 -> fn _state, args -> SatelliteMethods.method2(args) end
        :method3 -> fn _state, args -> SatelliteMethods.method3(args) end
        :method4 -> fn _state, args -> SatelliteMethods.method4(args) end
        :method5 -> fn _state, args -> SatelliteMethods.method5(args) end
        :method6 -> fn _state, args -> SatelliteMethods.method6(args) end
        :method7 -> fn _state, args -> SatelliteMethods.method7(args) end
        _ -> fn _state, _args -> {:error, "Unknown method"} end
      end
      # Assuming all methods are task methods for now
      Domain.add_task_method(acc_domain, Atom.to_string(method.task |> elem(0)), Atom.to_string(method.name), method_fn)
    end)
  end
end
