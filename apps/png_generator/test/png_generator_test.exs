defmodule PngGeneratorTest do
  use ExUnit.Case
  doctest PngGenerator

  @sample_schedule %{
    "activities" => [
      %{
        "name" => "Task A",
        "start_time" => "2025-01-01T09:00:00Z",
        "end_time" => "2025-01-01T11:00:00Z",
        "id" => "A1",
        "duration" => 2
      },
      %{
        "name" => "Task B",
        "start_time" => "2025-01-01T10:00:00Z",
        "end_time" => "2025-01-01T12:00:00Z",
        "id" => "B1",
        "duration" => 2
      }
    ]
  }

  describe "generate_timeline_png/2" do
    setup do
      test_dir = System.tmp_dir!() |> Path.join("png_generator_test")
      File.mkdir_p!(test_dir)

      on_exit(fn ->
        File.rm_rf!(test_dir)
      end)

      %{test_dir: test_dir}
    end

    test "generates PNG file successfully", %{test_dir: test_dir} do
      json_string = Jason.encode!(@sample_schedule)
      output_path = Path.join(test_dir, "timeline.png")

      assert {:ok, result_path} = PngGenerator.generate_timeline_png(json_string, output_path)
      assert File.exists?(result_path)

      # Verify it's a valid PNG file (starts with PNG signature)
      file_content = File.read!(result_path)
      png_signature = <<137, 80, 78, 71, 13, 10, 26, 10>>
      assert String.starts_with?(file_content, png_signature)
    end

    test "returns error for invalid JSON" do
      invalid_json = "{invalid json"
      output_path = "/tmp/test.png"

      assert {:error, error_msg} = PngGenerator.generate_timeline_png(invalid_json, output_path)
      assert String.contains?(error_msg, "Failed to parse JSON")
    end
  end
end
