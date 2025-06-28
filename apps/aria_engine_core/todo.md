Can you make sure @adr_serial R25W1398085 is authoritative over apps/aria_engine_core apis?

Can you correctly expose the @adr_serial R25W1398085 api of `run_lazy` and `plan` state and domain? here `apps/aria_engine_core/lib/aria_engine_core.ex`? 

```elixir
# Planning only - returns solution tree
@spec plan(AriaEngine.Domain.t(), AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree()}} | {:error, atom()}

# Planning + execution - returns final state  
@spec run_lazy(AriaEngine.Domain.t(), AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree()}} | {:error, atom()}

# Take a pre-made plan and execute it.
@spec run_lazy_tree(AriaEngine.Domain.t(), AriaState.t(), AriaEngineCore.Plan.solution_tree()) :: {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree()}} | {:error, atom()}
```

Restructure this app to follow the standard Elixir pattern of an external module with inner modules.
