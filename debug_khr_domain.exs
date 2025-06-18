# Debug script to test KHR domain registration and planning
alias StateV2
alias NodeLibrary.KHRInteractivityDomain
# Fix import path
import_if_available(GLTFSceneMock, from: "test/support/gltf_scene_mock.ex")
alias Domain.Core
alias Planner
alias PlannerAdapter

IO.puts("=== Debug KHR Domain Registration ===")

# Create domain with complete KHR registration
domain = Core.new()
|> KHRInteractivityDomain.register_complete_domain()

IO.puts("Domain created")

# Check domain structure
IO.puts("=== Domain Structure ===")
IO.puts("Actions registered: #{domain.actions |> Map.keys() |> length()}")
IO.puts("Task methods registered: #{domain.task_methods |> Map.keys() |> length()}")

# Show relevant task methods
IO.puts("Math/e task methods:")
IO.inspect(Map.get(domain.task_methods, "math/e"), label: "math/e")

IO.puts("Math/add task methods:")
IO.inspect(Map.get(domain.task_methods, "math/add"), label: "math/add")

# Initialize state directly (without GLTFSceneMock)
initial_state = StateV2.new()
|> StateV2.add_fact("test", "ready", true)

IO.puts("State initialized")

# Test different goal formats
IO.puts("=== Testing different approaches ===")

# Approach 1: Direct action execution
IO.puts("Testing direct action execution:")
case domain.actions[:khr_math_e] do
  nil -> IO.puts("Action not found")
  action_func -> 
    result_state = action_func.(initial_state, [0])
    node_value = StateV2.get_fact(result_state, 0, "value")
    IO.puts("Direct action result: #{inspect(node_value)}")
end

# Approach 2: Test task method directly
IO.puts("Testing task method directly:")
case Map.get(domain.task_methods, "math/e") do
  nil -> IO.puts("Task method not found")
  [{_name, task_func}] ->
    result = task_func.(initial_state, [0])
    IO.puts("Direct task method result: #{inspect(result)}")
  methods -> IO.puts("Multiple methods: #{inspect(methods)}")
end

# Approach 3: Test simple planning goal
goals_simple = ["math/e"]
IO.puts("Testing simple goal format: #{inspect(goals_simple)}")

case Planner.plan(domain, initial_state, goals_simple) do
  {:ok, plan} ->
    IO.puts("Simple planning succeeded!")
    IO.inspect(plan, label: "Plan")
  {:error, reason} ->
    IO.puts("Simple planning failed: #{inspect(reason)}")
end

# Approach 4: Test with original goal format
goals = [{"math/e", [0]}]
IO.puts("Testing original goal format: #{inspect(goals)}")

case Planner.plan(domain, initial_state, goals) do
  {:ok, plan} ->
    IO.puts("Original planning succeeded!")
    IO.inspect(plan, label: "Plan")
  {:error, reason} ->
    IO.puts("Original planning failed: #{inspect(reason)}")
end
