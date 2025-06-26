defmodule TestAttributeSystem do
  use AriaCore.Domain

  @action duration: "PT5M"
  def simple_action(_state, []) do
    IO.puts("DEBUG: simple_action defined")
    %{}
  end

  @unigoal_method predicate: "test_goal"
  def test_goal_method(_state, [subject, value]) do
    IO.puts("DEBUG: test_goal_method defined")
    {:ok, [
      {:simple_action, []},
      {"test_goal", subject, value}
    ]}
  end

  @task_method
  def test_task_method(_state, [task_id]) do
    IO.puts("DEBUG: test_task_method defined")
    {:ok, [
      {:simple_action, []},
      {"task_complete", task_id, true}
    ]}
  end
end

# Test if the attributes are recognized
IO.puts("Testing attribute system...")

try do
  metadata = TestAttributeSystem.__action_metadata__()
  IO.puts("✅ Action metadata: #{inspect(metadata)}")
rescue
  e -> IO.puts("❌ Action metadata error: #{inspect(e)}")
end

try do
  metadata = TestAttributeSystem.__unigoal_metadata__()
  IO.puts("✅ Unigoal metadata: #{inspect(metadata)}")
rescue
  e -> IO.puts("❌ Unigoal metadata error: #{inspect(e)}")
end

try do
  metadata = TestAttributeSystem.__method_metadata__()
  IO.puts("✅ Method metadata: #{inspect(metadata)}")
rescue
  e -> IO.puts("❌ Method metadata error: #{inspect(e)}")
end

try do
  domain = TestAttributeSystem.create_domain()
  IO.puts("✅ Domain creation: #{inspect(domain.name)}")
rescue
  e -> IO.puts("❌ Domain creation error: #{inspect(e)}")
end
