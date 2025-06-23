#!/usr/bin/env elixir

# Quick fix script to correct malformed @spec lines in serial_number functions

defmodule SerialNumberSpecFixer do
  def run do
    IO.puts("🔧 Fixing malformed @spec lines in serial_number functions...")

    # Find all files with the malformed @spec pattern
    files = Path.wildcard("**/*.{ex,exs}", match_dot: true)
    |> Enum.filter(&File.exists?/1)
    |> Enum.filter(fn file ->
      content = File.read!(file)
      String.contains?(content, "@spec serial_number() :: String.t()")
    end)

    IO.puts("Found #{length(files)} files with malformed @spec lines")

    Enum.each(files, &fix_file/1)

    IO.puts("✅ Fixed all malformed @spec lines!")
  end

  defp fix_file(file) do
    content = File.read!(file)

    # Fix the malformed @spec line
    fixed_content = String.replace(
      content,
      "@spec serial_number() :: String.t()",
      "@spec serial_number() :: String.t()"
    )

    # Also remove any stray nil statements
    fixed_content = String.replace(fixed_content, "\n  nil\n", "\n")

    if fixed_content != content do
      File.write!(file, fixed_content)
      IO.puts("   ✅ Fixed: #{file}")
    end
  end
end

SerialNumberSpecFixer.run()
