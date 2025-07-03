# Debug script to trace unigoal method registration
# Run with: elixir -S mix run debug_unigoal_registration.exs

# First, let's check what metadata is being collected by the attribute system
IO.puts("=== Debugging Unigoal Method Registration ===\n")

# Check if the domain module has the registration function
if function_exported?(AriaBlocksWorld.Domain, :__register_action_attributes__, 0) do
  IO.puts("✓ __register_action_attributes__/0 function exists")

  # Call the registration function to populate Process dictionary
  AriaBlocksWorld.Domain.__register_action_attributes__()

  # Check what was stored in Process dictionary
  IO.puts("\n--- Process Dictionary Contents ---")
  unigoal_specs = Process.get({AriaBlocksWorld.Domain, :unigoal_specs})
  IO.puts("Unigoal specs: #{inspect(unigoal_specs, pretty: true)}")

  action_specs = Process.get({AriaBlocksWorld.Domain, :action_specs})
  IO.puts("Action specs count: #{if action_specs, do: length(action_specs), else: 0}")

  method_specs = Process.get({AriaBlocksWorld.Domain, :method_specs})
  IO.puts("Method specs count: #{if method_specs, do: length(method_specs), else: 0}")
else
  IO.puts("✗ __register_action_attributes__/0 function not found")
end

# Check the raw metadata functions
IO.puts("\n--- Raw Metadata Functions ---")
if function_exported?(AriaBlocksWorld.Domain, :__unigoal_metadata__, 0) do
  unigoal_metadata = AriaBlocksWorld.Domain.__unigoal_metadata__()
  IO.puts("Raw unigoal metadata: #{inspect(unigoal_metadata, pretty: true)}")
else
  IO.puts("✗ __unigoal_metadata__/0 function not found")
end

# Now let's create a domain and see what gets registered
IO.puts("\n--- Domain Creation and Registration ---")
domain = AriaBlocksWorld.Domain.create()
IO.puts("Domain created: #{inspect(Map.keys(domain))}")

# Check unigoal methods in the domain
unigoal_methods = Map.get(domain, :unigoal_methods, %{})
IO.puts("Unigoal methods in domain: #{inspect(unigoal_methods, pretty: true)}")

# Check if "pos" predicate is registered
pos_methods = Map.get(unigoal_methods, "pos", %{})
IO.puts("Methods for 'pos' predicate: #{inspect(pos_methods, pretty: true)}")

# Check if "clear" predicate is registered
clear_methods = Map.get(unigoal_methods, "clear", %{})
IO.puts("Methods for 'clear' predicate: #{inspect(clear_methods, pretty: true)}")

# Test the AriaCore registration function directly
IO.puts("\n--- Testing AriaCore Registration ---")
test_domain = AriaCore.new_domain(:test)
test_domain_with_specs = AriaCore.register_attribute_specs(test_domain, AriaBlocksWorld.Domain)

test_unigoal_methods = Map.get(test_domain_with_specs, :unigoal_methods, %{})
IO.puts("Test domain unigoal methods: #{inspect(test_unigoal_methods, pretty: true)}")

# Clean up Process dictionary
Process.delete({AriaBlocksWorld.Domain, :unigoal_specs})
Process.delete({AriaBlocksWorld.Domain, :action_specs})
Process.delete({AriaBlocksWorld.Domain, :method_specs})

IO.puts("\n=== Debug Complete ===")
