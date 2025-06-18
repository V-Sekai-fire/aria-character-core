# Test conversion behavior
IO.puts("Testing conversion of [1]:")
IO.inspect([1] |> to_string())
IO.inspect([1] |> inspect())

IO.puts("\nTesting pattern matching:")
goal = {"math/pi", [1]}
case goal do
  {task_name, args} when is_binary(task_name) and is_list(args) ->
    IO.puts("✅ Matched as task: #{inspect(task_name)}, #{inspect(args)}")
  {predicate, subject, fact_value} ->
    IO.puts("❌ Matched as goal: #{inspect(predicate)}, #{inspect(subject)}, #{inspect(fact_value)}")
  _ ->
    IO.puts("❓ No match")
end

# Test what happens when we try to convert [1] to string in goal context
IO.puts("\nTesting goal conversion:")
{predicate, subject, fact_value} = {"math/pi", [1], nil}
IO.puts("predicate: #{inspect(predicate)}")
IO.puts("subject: #{inspect(subject)}")
IO.puts("subject as string: #{inspect(to_string(subject))}")
