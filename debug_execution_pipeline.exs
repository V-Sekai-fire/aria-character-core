# Debug script for KHR execution pipeline
# Usage: mix run debug_execution_pipeline.exs

Code.require_file("test/aria_engine/test/support/gltf_scene_mock.ex")

defmodule ExecutionPipelineDebug do
  alias StateV2
  alias NodeLibrary.KHRInteractivityDomain
  alias NodeLibrary.KHRInteractivity.Support.GLTFSceneMock
  alias Domain.Core
  alias Planner
  alias PlannerAdapter

  def run_all_tests do
    IO.puts("=== KHR Execution Pipeline Debug ===\n")
    
    test_planning_vs_execution()
    test_execution_step_by_step()
    test_direct_action_execution()
  end

  def test_planning_vs_execution do
    IO.puts("=== Testing Planning vs Execution Separation ===")
    
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    state = StateV2.new()
    |> GLTFSceneMock.setup_state_with_scene()
    
    goals = [{"math/pi", [1]}]
    
    IO.puts("Goals: #{inspect(goals)}")
    
    # Step 1: Planning phase
    IO.puts("\n--- PLANNING PHASE ---")
    case Planner.plan(domain, state, goals) do
      {:ok, plan} ->
        IO.puts("✅ Planning succeeded")
        IO.puts("Plan structure: #{inspect(Map.keys(plan))}")
        
        # Examine the plan structure
        if Map.has_key?(plan, :nodes) do
          IO.puts("Plan has #{map_size(plan.nodes)} nodes")
          
          # Show primitive actions in the plan
          primitive_actions = plan.nodes
          |> Enum.filter(fn {_id, node} -> Map.get(node, :is_primitive, false) end)
          |> Enum.map(fn {id, node} -> {id, node.task} end)
          
          IO.puts("Primitive actions to execute:")
          Enum.each(primitive_actions, fn {id, task} ->
            IO.puts("  #{id}: #{inspect(task)}")
          end)
        end
        
        # Step 2: Execution phase
        IO.puts("\n--- EXECUTION PHASE ---")
        case PlannerAdapter.run_lazy_refineahead(domain, state, plan) do
          {:ok, final_state} ->
            IO.puts("✅ Execution succeeded")
            
            # Check if node 1 has the pi value
            node_value = StateV2.get_fact(final_state, 1, "value")
            IO.puts("Node 1 value after execution: #{inspect(node_value)}")
            
            # Check GLTFSceneMock format
            gltf_value = GLTFSceneMock.get_node_property(final_state, 1, "value")
            IO.puts("Node 1 value via GLTFSceneMock: #{inspect(gltf_value)}")
            
          {:error, reason} ->
            IO.puts("❌ Execution failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Planning failed: #{inspect(reason)}")
    end
    
    IO.puts("\n" <> String.duplicate("=", 50) <> "\n")
  end

  def test_execution_step_by_step do
    IO.puts("=== Testing Execution Step by Step ===")
    
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    state = StateV2.new()
    |> GLTFSceneMock.setup_state_with_scene()
    
    goals = [{"math/pi", [1]}]
    
    case Planner.plan(domain, state, goals) do
      {:ok, plan} ->
        IO.puts("Plan created successfully")
        
        # Try to manually execute the primitive actions
        primitive_actions = plan.nodes
        |> Enum.filter(fn {_id, node} -> Map.get(node, :is_primitive, false) end)
        |> Enum.map(fn {_id, node} -> node.task end)
        
        IO.puts("Executing primitive actions manually:")
        
        final_state = Enum.reduce(primitive_actions, state, fn {action_name, args}, current_state ->
          IO.puts("  Executing: #{action_name} with args #{inspect(args)}")
          
          # Convert string action name to atom
          action_atom = String.to_atom(action_name)
          
          case Map.get(domain.actions, action_atom) do
            nil ->
              IO.puts("    ❌ Action #{action_atom} not found in domain")
              current_state
            action_func ->
              try do
                new_state = action_func.(current_state, args)
                IO.puts("    ✅ Action executed successfully")
                
                # Check if the value was set
                [node_id | _] = args
                value = StateV2.get_fact(new_state, node_id, "value")
                IO.puts("    Node #{node_id} value: #{inspect(value)}")
                
                new_state
              rescue
                error ->
                  IO.puts("    ❌ Action execution failed: #{inspect(error)}")
                  current_state
              end
          end
        end)
        
        # Final check
        final_value = StateV2.get_fact(final_state, 1, "value")
        IO.puts("Final node 1 value: #{inspect(final_value)}")
        
      {:error, reason} ->
        IO.puts("❌ Planning failed: #{inspect(reason)}")
    end
    
    IO.puts("\n" <> String.duplicate("=", 50) <> "\n")
  end

  def test_direct_action_execution do
    IO.puts("=== Testing Direct Action Execution ===")
    
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    state = StateV2.new()
    |> GLTFSceneMock.setup_state_with_scene()
    
    # Test direct action execution
    IO.puts("Testing direct khr_math_pi action:")
    
    case Map.get(domain.actions, :khr_math_pi) do
      nil ->
        IO.puts("❌ khr_math_pi action not found")
      action_func ->
        try do
          final_state = action_func.(state, [1])
          
          # Check StateV2 direct access
          direct_value = StateV2.get_fact(final_state, 1, "value")
          IO.puts("Direct StateV2 access - Node 1 value: #{inspect(direct_value)}")
          
          # Check GLTFSceneMock access
          gltf_value = GLTFSceneMock.get_node_property(final_state, 1, "value")
          IO.puts("GLTFSceneMock access - Node 1 value: #{inspect(gltf_value)}")
          
          # Check if GLTFSceneMock is looking in the right place
          IO.puts("Checking GLTFSceneMock node resolution:")
          node_id = GLTFSceneMock.resolve_node_to_data_id(final_state, 1)
          IO.puts("  Node 1 resolves to data ID: #{inspect(node_id)}")
          
          if node_id do
            resolved_value = StateV2.get_fact(final_state, node_id, "value")
            IO.puts("  Value at resolved ID: #{inspect(resolved_value)}")
          end
          
        rescue
          error ->
            IO.puts("❌ Direct action execution failed: #{inspect(error)}")
        end
    end
    
    IO.puts("\n" <> String.duplicate("=", 50) <> "\n")
  end
end

ExecutionPipelineDebug.run_all_tests()
