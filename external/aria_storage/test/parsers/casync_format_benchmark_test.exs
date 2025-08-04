# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

Code.require_file("../support/casync_fixtures.ex", __DIR__)

defmodule AriaStorage.Parsers.CasyncFormatBenchmarkTest do
  use ExUnit.Case
  alias AriaStorage.Parsers.CasyncFormat
  alias AriaStorage.TestFixtures.CasyncFixtures

  @moduledoc "Benchmark tests for the casync format parser.\n\nThese tests measure parsing performance across different file sizes\nand complexity levels to ensure the parser scales appropriately.\n"
  @testdata_path Path.join([__DIR__, "..", "support", "testdata"])
  describe("performance benchmarks") do
    test "benchmark parsing speed on real testdata" do
      if File.exists?(@testdata_path) do
        testdata_files = [
          {"blob1.caibx", &CasyncFormat.parse_index/1},
          {"flat.catar", &CasyncFormat.parse_archive/1},
          {"nested.catar", &CasyncFormat.parse_archive/1},
          {"complex.catar", &CasyncFormat.parse_archive/1}
        ]

        results =
          Enum.map(testdata_files, fn {filename, parser_func} ->
            file_path = Path.join(@testdata_path, filename)

            case File.read(file_path) do
              {:ok, data} ->
                file_size = byte_size(data)
                parser_func.(data)
                {time_micro, result} = :timer.tc(parser_func, [data])

                case result do
                  {:ok, parsed} ->
                    throughput = file_size / (time_micro / 1_000_000)
                    TestOutput.trace_puts("
#{filename}:")
                    TestOutput.trace_puts("  File size: #{file_size} bytes")

                    TestOutput.trace_puts(
                      "  Parse time: #{time_micro} μs (#{time_micro / 1000} ms)"
                    )

                    TestOutput.trace_puts(
                      "  Throughput: #{Float.round(throughput / 1024 / 1024, 2)} MB/s"
                    )

                    assert time_micro < 100_000
                    assert throughput > 1024
                    {filename, file_size, time_micro, throughput, parsed}

                  {:error, reason} ->
                    TestOutput.trace_puts("#{filename}: Failed to parse - #{inspect(reason)}")
                    {filename, file_size, :error, 0, nil}
                end

              {:error, _} ->
                TestOutput.trace_puts("#{filename}: File not found, skipping")
                {filename, 0, :not_found, 0, nil}
            end
          end)

        successful_results = Enum.filter(results, fn {_, _, time, _, _} -> is_integer(time) end)

        if length(successful_results) > 0 do
          total_time = Enum.sum(Enum.map(successful_results, fn {_, _, time, _, _} -> time end))
          total_size = Enum.sum(Enum.map(successful_results, fn {_, size, _, _, _} -> size end))
          avg_throughput = total_size / (total_time / 1_000_000)
          TestOutput.trace_puts("\nSummary:")
          TestOutput.trace_puts("  Files processed: #{length(successful_results)}")
          TestOutput.trace_puts("  Total size: #{total_size} bytes")
          TestOutput.trace_puts("  Total time: #{total_time} μs")

          TestOutput.trace_puts(
            "  Average throughput: #{Float.round(avg_throughput / 1024 / 1024, 2)} MB/s"
          )
        end
      else
        TestOutput.trace_puts("Testdata directory not found, skipping benchmark")
      end
    end

    test "benchmark synthetic data scaling" do
      chunk_counts = [1, 10, 50, 100, 500, 1000]
      TestOutput.trace_puts("\nSynthetic Data Scaling Benchmark:")

      results =
        Enum.map(chunk_counts, fn chunk_count ->
          data = CasyncFixtures.create_multi_chunk_caibx(chunk_count)
          file_size = byte_size(data)
          CasyncFormat.parse_index(data)

          times =
            for _i <- 1..5 do
              {time_micro, _result} = :timer.tc(CasyncFormat, :parse_index, [data])
              time_micro
            end

          avg_time = Enum.sum(times) / length(times)
          min_time = Enum.min(times)
          max_time = Enum.max(times)
          throughput = file_size / (avg_time / 1_000_000)
          TestOutput.trace_puts("  #{chunk_count} chunks (#{file_size} bytes):")

          TestOutput.trace_puts(
            "    Avg: #{Float.round(avg_time)} μs, Min: #{min_time} μs, Max: #{max_time} μs"
          )

          TestOutput.trace_puts(
            "    Throughput: #{Float.round(throughput / 1024 / 1024, 2)} MB/s"
          )

          {chunk_count, file_size, avg_time, throughput}
        end)

      Enum.each(results, fn {chunk_count, _size, time, _throughput} ->
        expected_max_time = chunk_count * 100

        assert time < expected_max_time,
               "Parsing #{chunk_count} chunks took #{time} μs, expected < #{expected_max_time} μs"
      end)
    end

    test "benchmark memory usage" do
      if System.get_env("BENCHMARK_MEMORY") == "true" do
        chunk_counts = [100, 500, 1000]
        TestOutput.trace_puts("\nMemory Usage Benchmark:")

        Enum.each(chunk_counts, fn chunk_count ->
          data = CasyncFixtures.create_multi_chunk_caibx(chunk_count)
          :erlang.garbage_collect()
          {memory_before, _} = :erlang.process_info(self(), :memory)
          {:ok, result} = CasyncFormat.parse_index(data)
          :erlang.garbage_collect()
          {memory_after, _} = :erlang.process_info(self(), :memory)
          memory_used = memory_after - memory_before
          file_size = byte_size(data)
          result_size = :erts_debug.size(result) * :erlang.system_info(:wordsize)
          TestOutput.trace_puts("  #{chunk_count} chunks:")
          TestOutput.trace_puts("    Input size: #{file_size} bytes")
          TestOutput.trace_puts("    Result size: #{result_size} bytes")
          TestOutput.trace_puts("    Memory used: #{memory_used} bytes")
          TestOutput.trace_puts("    Memory ratio: #{Float.round(memory_used / file_size, 2)}x")

          assert memory_used < file_size * 10,
                 "Memory usage #{memory_used} exceeds 10x input size #{file_size}"
        end)
      else
        TestOutput.trace_puts("Skipping memory benchmark (set BENCHMARK_MEMORY=true to enable)")
      end
    end

    test "benchmark parser comparison" do
      data = CasyncFixtures.create_multi_chunk_caibx(100)
      parsers = [{"current_parser", &CasyncFormat.parse_index/1}]
      TestOutput.trace_puts("\nParser Comparison:")

      Enum.each(parsers, fn {name, parser_func} ->
        parser_func.(data)

        times =
          for _i <- 1..10 do
            {time_micro, _result} = :timer.tc(parser_func, [data])
            time_micro
          end

        avg_time = Enum.sum(times) / length(times)

        std_dev =
          :math.sqrt(
            Enum.sum(Enum.map(times, fn t -> (t - avg_time) * (t - avg_time) end)) / length(times)
          )

        TestOutput.trace_puts("  #{name}:")
        TestOutput.trace_puts("    Average: #{Float.round(avg_time)} μs")
        TestOutput.trace_puts("    Std dev: #{Float.round(std_dev)} μs")
        TestOutput.trace_puts("    Range: #{Enum.min(times)}-#{Enum.max(times)} μs")
      end)
    end

    test "benchmark concurrent parsing" do
      data = CasyncFixtures.create_multi_chunk_caibx(50)
      concurrency_levels = [1, 2, 4, 8, 16]
      TestOutput.trace_puts("\nConcurrent Parsing Benchmark:")

      Enum.each(concurrency_levels, fn concurrency ->
        tasks =
          for _i <- 1..concurrency do
            Task.async(fn ->
              {time_micro, _result} = :timer.tc(CasyncFormat, :parse_index, [data])
              time_micro
            end)
          end

        {total_time, results} = :timer.tc(fn -> Task.await_many(tasks, 10000) end)
        avg_parse_time = Enum.sum(results) / length(results)
        TestOutput.trace_puts("  #{concurrency} concurrent parses:")
        TestOutput.trace_puts("    Total time: #{total_time} μs")
        TestOutput.trace_puts("    Avg parse time: #{Float.round(avg_parse_time)} μs")

        TestOutput.trace_puts(
          "    Efficiency: #{Float.round(100 * avg_parse_time / total_time)}%"
        )

        assert total_time < avg_parse_time * concurrency * 10,
               "Concurrent parsing is excessively slow (#{total_time} μs vs expected max #{avg_parse_time * concurrency * 10} μs)"
      end)
    end
  end

  describe("stress testing") do
    test "stress test with many small files" do
      small_files =
        for _i <- 1..100 do
          CasyncFixtures.create_minimal_caibx()
        end

      {total_time, results} =
        :timer.tc(fn -> Enum.map(small_files, &CasyncFormat.parse_index/1) end)

      successful_parses =
        Enum.count(results, fn
          {:ok, _} -> true
          _ -> false
        end)

      TestOutput.trace_puts("\nStress Test - Many Small Files:")
      TestOutput.trace_puts("  Files: #{length(small_files)}")
      TestOutput.trace_puts("  Successful: #{successful_parses}")
      TestOutput.trace_puts("  Total time: #{total_time} μs")
      TestOutput.trace_puts("  Avg per file: #{Float.round(total_time / length(small_files))} μs")
      assert successful_parses == length(small_files)
      assert total_time < 1_000_000
    end

    test "stress test with large files" do
      large_data = CasyncFixtures.create_multi_chunk_caibx(2000)
      {time_micro, result} = :timer.tc(CasyncFormat, :parse_index, [large_data])

      case result do
        {:ok, parsed} ->
          TestOutput.trace_puts("\nStress Test - Large File:")
          TestOutput.trace_puts("  Input size: #{byte_size(large_data)} bytes")
          TestOutput.trace_puts("  Chunks: #{length(parsed.chunks)}")
          TestOutput.trace_puts("  Parse time: #{time_micro} μs")

          TestOutput.trace_puts(
            "  Time per chunk: #{Float.round(time_micro / length(parsed.chunks), 2)} μs"
          )

          assert time_micro < 1_000_000
          assert length(parsed.chunks) == 2000

        {:error, reason} ->
          flunk("Failed to parse large file: #{inspect(reason)}")
      end
    end
  end
end
