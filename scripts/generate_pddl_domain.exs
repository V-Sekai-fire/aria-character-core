# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule GeneratePddlDomain do
  alias AriaEngine.Domain
  alias AriaEngine.Pddl.DomainAdapter

  def run do
    IO.puts("=== Generating PDDL Domain ===")

    # Create a simple AriaEngine Domain
    aria_domain = Domain.new("simple_test_domain")
    |> Domain.add_action(:move, fn state, [from, to] -> # Removed underscore
      IO.puts("Executing move from #{from} to #{to}")
      state # Return state to satisfy function signature
    end)
    |> Domain.add_action(:pickup, fn state, [item] -> # Removed underscore
      IO.puts("Executing pickup #{item}")
      state # Return state to satisfy function signature
    end)
    |> Domain.add_task_method("get_item", fn state, [item] -> # Removed underscore
      IO.puts("Getting item #{item}")
      [{:pickup, [item]}]
    end)

    IO.puts("\nAriaEngine Domain created: #{inspect(aria_domain.name)}")

    # Convert AriaEngine Domain to PDDL Domain using the adapter
    pddl_domain = DomainAdapter.to_pddl_domain(aria_domain)

    IO.puts("\n--- Generated PDDL Domain ---")
    IO.inspect(pddl_domain, pretty: true)

    IO.puts("\n--- PDDL Domain String (Placeholder) ---")
    # In a real scenario, you would format the pddl_domain struct into a PDDL string
    # For now, we'll just show a placeholder.
    IO.puts("(define (domain #{pddl_domain.name})")
    IO.puts("  (:requirements #{Enum.map_join(pddl_domain.requirements, " ", &":#{&1}")})")
    IO.puts("  (:types #{Enum.map_join(pddl_domain.types, " ")})")
    IO.puts("  (:predicates #{Enum.map_join(pddl_domain.predicates, " ", fn {p, args} -> "(#{p} #{Enum.join(args, " ")})" end)})")
    IO.puts("  (:actions")
    # Placeholder for actions
    IO.puts("    ; Actions will be listed here")
    IO.puts("  )")
    IO.puts(")")
  end
end

GeneratePddlDomain.run()
