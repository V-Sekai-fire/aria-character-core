defmodule JsonSolution.FileWriter do
  @moduledoc """
  File Writer Utility
  
  Handles writing JSON and markdown files to the output directory.
  """
  
  require Logger
  
  @output_dir Path.join(["priv", "schedule_images"])
  
  def ensure_output_directory do
    File.mkdir_p!(@output_dir)
    @output_dir
  end
  
  def write_json_file(data, filename) do
    output_dir = ensure_output_directory()
    file_path = Path.join([output_dir, filename])
    
    try do
      json_content = Jason.encode!(data, pretty: true)
      File.write!(file_path, json_content)
      Logger.info("✅ Generated: #{filename}")
      {:ok, file_path}
    rescue
      error ->
        Logger.warning("❌ Failed to write #{filename}: #{inspect(error)}")
        {:error, error}
    end
  end
  
  def write_markdown_file(content, filename) do
    output_dir = ensure_output_directory()
    file_path = Path.join([output_dir, filename])
    
    try do
      File.write!(file_path, content)
      Logger.info("✅ Generated: #{filename}")
      {:ok, file_path}
    rescue
      error ->
        Logger.warning("❌ Failed to write #{filename}: #{inspect(error)}")
        {:error, error}
    end
  end
  
  def get_output_directory do
    @output_dir
  end
  
  def list_generated_files do
    output_dir = ensure_output_directory()
    
    case File.ls(output_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(fn file -> 
          String.ends_with?(file, ".json") or String.ends_with?(file, ".md")
        end)
        |> Enum.sort()
        
      {:error, _reason} ->
        []
    end
  end
  
  def clean_output_directory do
    output_dir = ensure_output_directory()
    
    case File.ls(output_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(fn file -> 
          String.ends_with?(file, ".json") or String.ends_with?(file, ".md")
        end)
        |> Enum.each(fn file ->
          file_path = Path.join([output_dir, file])
          File.rm(file_path)
        end)
        
        Logger.info("🧹 Cleaned output directory")
        
      {:error, reason} ->
        Logger.warning("Failed to clean output directory: #{reason}")
    end
  end
end
