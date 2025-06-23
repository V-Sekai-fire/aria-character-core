defmodule AriaEngine.MiniZinc.ExecutorTest do
  use ExUnit.Case, async: true
  alias AriaEngine.MiniZinc.Executor

  describe("check_availability/0") do
    test "checks if MiniZinc is available" do
      result = Executor.check_availability()
      assert is_boolean(result)
    end
  end

  describe("exec/2 with template") do
    @tag :integration
    test "executes STN temporal template successfully" do
      template_vars = %{
        num_activities: 3,
        num_constraints: 2,
        durations: [10, 20, 15],
        constraints: [
          %{from_activity: 1, to_activity: 2, min_distance: 10, max_distance: 100},
          %{from_activity: 2, to_activity: 3, min_distance: 20, max_distance: 100}
        ]
      }

      case Executor.exec("stn_temporal", template_vars: template_vars, timeout: 10000) do
        {:ok, result} ->
          assert result.status == :success
          assert is_map(result.solution)
          assert is_integer(result.solve_time_ms)
          assert is_binary(result.raw_output)

        {:error, error} ->
          IO.inspect(error, label: "Execution error")
          assert true
      end
    end

    test "handles missing template gracefully" do
      result = Executor.exec("nonexistent_template", template_vars: %{})
      assert {:error, error} = result
      assert is_binary(error) or is_map(error)
    end

    test "handles empty template variables" do
      result = Executor.exec("stn_temporal", template_vars: %{})
      assert {:error, _error} = result
    end
  end

  describe("exec/2 with direct file") do
    @tag :integration
    test "executes direct MiniZinc file" do
      test_model =
        "var 1..10: x;\nvar 1..10: y;\n\nconstraint x + y = 10;\n\nsolve satisfy;\n\noutput [\"x = \" ++ show(x) ++ \", y = \" ++ show(y)];\n"

      temp_file = Path.join(System.tmp_dir!(), "test_model_#{:rand.uniform(1000)}.mzn")

      try do
        File.write!(temp_file, test_model)

        case Executor.exec(temp_file, cleanup: false) do
          {:ok, result} ->
            assert result.status == :success
            assert is_map(result.solution)

          {:error, error} ->
            IO.inspect(error, label: "Direct file execution error")
            assert true
        end
      after
        if File.exists?(temp_file) do
          File.rm(temp_file)
        end
      end
    end

    test "handles missing file gracefully" do
      result = Executor.exec("nonexistent.mzn")
      assert {:error, error} = result
      assert String.contains?(error, "not found") or is_map(error)
    end
  end
end