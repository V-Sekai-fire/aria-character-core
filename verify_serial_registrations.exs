#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Comprehensive Aria Serial Registration Verification Script
# Checks all @serial_number declarations against JSON registry storage

defmodule SerialVerifier do
  @moduledoc """
  Verifies that all aria_serials are properly registered in the JSON storage system.
  """

  def run do
    IO.puts("🔍 Aria Serial Registration Verification")
    IO.puts("=" |> String.duplicate(50))

    # Extract all serial numbers from different sources
    code_serials = extract_code_serials()
    filename_serials = extract_filename_serials()
    registry_serials = extract_registry_serials()

    # Perform verification
    verify_registrations(code_serials, filename_serials, registry_serials)
  end

  defp extract_code_serials do
    IO.puts("\n📋 Extracting @serial_number declarations from code...")

    code_serials =
      Path.wildcard("**/*.ex", match_dot: true)
      |> Enum.flat_map(fn file ->
        case File.read(file) do
          {:ok, content} ->
            Regex.scan(~r/@serial_number\s+"([^"]*)"/, content, capture: :all_but_first)
            |> Enum.map(fn [serial] -> {serial, file} end)
          {:error, _} -> []
        end
      end)

    IO.puts("Found #{length(code_serials)} @serial_number declarations:")
    Enum.each(code_serials, fn {serial, file} ->
      IO.puts("  #{serial} in #{file}")
    end)

    code_serials
  end

  defp extract_filename_serials do
    IO.puts("\n📁 Extracting serial numbers from filenames...")

    filename_serials =
      Path.wildcard("decisions/R25W*.md")
      |> Enum.map(fn file ->
        case Regex.run(~r/decisions\/(R25W[0-9A-Z]+)/, file, capture: :all_but_first) do
          [serial] -> {serial, file}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    IO.puts("Found #{length(filename_serials)} serial numbers in decision filenames:")
    Enum.each(filename_serials, fn {serial, file} ->
      IO.puts("  #{serial} in #{file}")
    end)

    filename_serials
  end

  defp extract_registry_serials do
    IO.puts("\n🗄️  Extracting registered serials from JSON storage...")

    registry_files = [
      "apps/aria_serial/priv/serial_data/2025/week_26/R_series.json",
      "apps/aria_serial/priv/serial_data/2025/week_45/R_series.json"
    ]

    registry_serials =
      registry_files
      |> Enum.flat_map(fn file ->
        case File.read(file) do
          {:ok, content} ->
            case Jason.decode(content) do
              {:ok, data} ->
                serials = Map.get(data, "serials", %{})
                Enum.map(serials, fn {serial, info} -> {serial, file, info} end)
              {:error, _} -> []
            end
          {:error, _} -> []
        end
      end)

    IO.puts("Found #{length(registry_serials)} registered serials:")
    Enum.each(registry_serials, fn {serial, file, _info} ->
      IO.puts("  #{serial} in #{file}")
    end)

    registry_serials
  end

  defp verify_registrations(code_serials, filename_serials, registry_serials) do
    IO.puts("\n🔍 Verification Results")
    IO.puts("=" |> String.duplicate(30))

    # Extract just the serial numbers for comparison
    code_serial_numbers = Enum.map(code_serials, fn {serial, _} -> serial end) |> MapSet.new()
    filename_serial_numbers = Enum.map(filename_serials, fn {serial, _} -> serial end) |> MapSet.new()
    registry_serial_numbers = Enum.map(registry_serials, fn {serial, _, _} -> serial end) |> MapSet.new()

    all_serials = MapSet.union(code_serial_numbers, filename_serial_numbers)

    # Check for unregistered serials
    unregistered = MapSet.difference(all_serials, registry_serial_numbers)

    if MapSet.size(unregistered) > 0 do
      IO.puts("\n❌ UNREGISTERED SERIALS (#{MapSet.size(unregistered)}):")
      Enum.each(unregistered, fn serial ->
        code_file = find_source_file(serial, code_serials)
        filename_file = find_source_file(serial, filename_serials)

        IO.puts("  #{serial}")
        if code_file, do: IO.puts("    - Found in code: #{code_file}")
        if filename_file, do: IO.puts("    - Found in filename: #{filename_file}")
      end)
    else
      IO.puts("\n✅ All serials are registered!")
    end

    # Check for registry-only serials (registered but not found in code/filenames)
    orphaned = MapSet.difference(registry_serial_numbers, all_serials)

    if MapSet.size(orphaned) > 0 do
      IO.puts("\n⚠️  ORPHANED REGISTRATIONS (#{MapSet.size(orphaned)}):")
      IO.puts("    (Registered but no corresponding code/filename found)")
      Enum.each(orphaned, fn serial ->
        registry_file = find_registry_file(serial, registry_serials)
        IO.puts("  #{serial} - registered in #{registry_file}")
      end)
    end

    # Check for module name mismatches
    check_module_mismatches(code_serials)

    # Summary
    IO.puts("\n📊 SUMMARY")
    IO.puts("=" |> String.duplicate(20))
    IO.puts("Code @serial_number declarations: #{MapSet.size(code_serial_numbers)}")
    IO.puts("Filename serial numbers: #{MapSet.size(filename_serial_numbers)}")
    IO.puts("Registered serials: #{MapSet.size(registry_serial_numbers)}")
    IO.puts("Unregistered serials: #{MapSet.size(unregistered)}")
    IO.puts("Orphaned registrations: #{MapSet.size(orphaned)}")

    if MapSet.size(unregistered) == 0 and MapSet.size(orphaned) == 0 do
      IO.puts("\n🎉 ALL SERIALS ARE PROPERLY REGISTERED!")
    else
      IO.puts("\n🔧 REGISTRATION ISSUES FOUND - See details above")
    end
  end

  defp find_source_file(serial, source_list) do
    case Enum.find(source_list, fn {s, _} -> s == serial end) do
      {_, file} -> file
      nil -> nil
    end
  end

  defp find_registry_file(serial, registry_serials) do
    case Enum.find(registry_serials, fn {s, _, _} -> s == serial end) do
      {_, file, _} -> file
      nil -> nil
    end
  end

  defp check_module_mismatches(code_serials) do
    IO.puts("\n🔍 Checking for module name mismatches...")

    mismatches =
      code_serials
      |> Enum.filter(fn {_serial, file} ->
        case File.read(file) do
          {:ok, content} ->
            # Extract defmodule name
            case Regex.run(~r/defmodule\s+([^\s]+)/, content, capture: :all_but_first) do
              [module_name] ->
                expected_module = expected_module_name(file)
                module_name != expected_module
              _ -> false
            end
          {:error, _} -> false
        end
      end)

    if length(mismatches) > 0 do
      IO.puts("\n⚠️  MODULE NAME MISMATCHES (#{length(mismatches)}):")
      Enum.each(mismatches, fn {serial, file} ->
        {:ok, content} = File.read(file)
        [actual_module] = Regex.run(~r/defmodule\s+([^\s]+)/, content, capture: :all_but_first)
        expected_module = expected_module_name(file)

        IO.puts("  #{serial} in #{file}")
        IO.puts("    - Actual: #{actual_module}")
        IO.puts("    - Expected: #{expected_module}")
      end)
    else
      IO.puts("✅ No module name mismatches found")
    end
  end

  defp expected_module_name(file) do
    cond do
      String.contains?(file, "aria_serial.ex") -> "AriaSerial"
      String.contains?(file, "application.ex") -> "AriaSerial.Application"
      String.contains?(file, "registry.ex") -> "AriaSerial.Registry"
      String.contains?(file, "json_storage.ex") -> "AriaSerial.JsonStorage"
      String.contains?(file, "create_serial.ex") -> "Mix.Tasks.Serial.Create"
      String.contains?(file, "decode.ex") -> "Mix.Tasks.Serial.Decode"
      String.contains?(file, "lookup_serial.ex") -> "Mix.Tasks.Serial.Lookup"
      true -> "Unknown"
    end
  end
end

# Add Jason dependency for JSON parsing
Mix.install([{:jason, "~> 1.4"}])

# Run the verification
SerialVerifier.run()
