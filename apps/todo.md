Perfect! Now I have the complete dependency analysis. Here's the **complete leaf-order testing sequence** organized by dependency tiers:

**Complete Leaf-Order Testing Plan:**

**Tier 1: Leaf apps (no internal dependencies) - 10 apps**

1. `mix test apps/aria_auth`
2. `mix test apps/aria_serial`
3. `mix test apps/aria_state`
4. `mix test apps/aria_storage`
5. `mix test apps/aria_town`
6. `mix test apps/aria_gltf`
7. `mix test apps/aria_security`
8. `mix test apps/aria_timeline_intervals`
9. `mix test apps/aria_minizinc_executor`
10. `mix test apps/ast_migrate`

**Tier 2: Single-dependency apps - 3 apps** 11. `mix test apps/aria_minizinc_stn` (→ aria_minizinc_executor) 12. `mix test apps/aria_minizinc_goal` (→ aria_minizinc_executor) 13. `mix test apps/aria_minizinc_multiply` (→ aria_minizinc_executor)

**Tier 3: Timeline layer - 1 app** 14. `mix test apps/aria_timeline` (→ aria_minizinc_stn)

**Tier 4: Engine core - 1 app** 15. `mix test apps/aria_engine_core` (→ aria_state, aria_timeline, aria_minizinc_stn, aria_minizinc_goal, aria_minizinc_executor)

**Tier 5: Higher-level integration - 2 apps** 16. `mix test apps/aria_core` (→ aria_engine_core, aria_state) 17. `mix test apps/aria_hybrid_planner` (→ aria_state, aria_timeline, aria_minizinc_stn, aria_engine_core)

**Tier 6: Top-level apps - 1 app** 18. `mix test apps/aria_membrane_pipeline` (→ aria_engine_core, aria_hybrid_planner, aria_minizinc_goal)

**Additional Note:** I also noticed the test failure you mentioned regarding duration parsing. The issue is that `duration: "PT1H"` (ISO 8601 for 1 hour) should be converted to a proper time unit structure, not just `{:fixed, 1800}` with unitless seconds. This looks like a bug in the `UnifiedActionSpecification` duration parsing logic that we should address.

Ready to proceed with this systematic leaf-order testing approach, and we can investigate the duration parsing issue when we get to the aria_core tests?
