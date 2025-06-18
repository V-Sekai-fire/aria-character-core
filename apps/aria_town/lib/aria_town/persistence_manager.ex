# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTown.PersistenceManager do
  @moduledoc """
  Manages periodic JSON-LD persistence with capped memory strategy.
  Saves NPC knowledge to chibifire.com-formatted files every 2 minutes.
  """
  
  use GenServer
  require Logger
  
  @save_interval_ms 2 * 60 * 1000           # Save every 2 minutes
  @max_conversations_per_npc 50             # Cap conversation history
  @max_knowledge_items_per_npc 100          # Cap knowledge facts
  @max_total_file_size_mb 10                # Cap JSON-LD file size
  @knowledge_file "priv/chibifire_npc_knowledge.jsonld"
  @backup_dir "priv/backups/"
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
  
  def init(state) do
    # Ensure directories exist
    ensure_directories()
    
    # Load existing knowledge on startup
    restore_knowledge()
    
    # Schedule periodic saves
    schedule_save()
    {:ok, state}
  end
  
  def handle_info(:save_knowledge, state) do
    save_knowledge_to_jsonld()
    schedule_save()
    {:noreply, state}
  end
  
  def trigger_save() do
    GenServer.cast(__MODULE__, :immediate_save)
  end
  
  def handle_cast(:immediate_save, state) do
    save_knowledge_to_jsonld()
    {:noreply, state}
  end
  
  defp schedule_save() do
    Process.send_after(self(), :save_knowledge, @save_interval_ms)
  end
  
  defp ensure_directories() do
    File.mkdir_p!(Path.dirname(@knowledge_file))
    File.mkdir_p!(@backup_dir)
  end
  
  defp restore_knowledge() do
    case File.read(@knowledge_file) do
      {:ok, content} ->
        try do
          json_data = Jason.decode!(content)
          graph = RDF.JSON.LD.Decoder.decode!(json_data)
          AriaTown.KnowledgeBase.set_graph(graph)
          Logger.info("Restored NPC knowledge from #{@knowledge_file}")
        rescue
          error ->
            Logger.error("Failed to decode knowledge file: #{inspect(error)}")
            Logger.info("Starting with fresh knowledge base")
        end
        
      {:error, :enoent} ->
        Logger.info("No existing knowledge file, starting fresh")
        
      {:error, reason} ->
        Logger.error("Failed to load knowledge: #{reason}")
    end
  end
  
  defp save_knowledge_to_jsonld() do
    graph = AriaTown.KnowledgeBase.get_graph()
    
    # Apply memory caps before saving
    capped_graph = apply_memory_caps(graph)
    
    # Check file size limit
    if estimated_size_mb(capped_graph) > @max_total_file_size_mb do
      capped_graph = aggressive_cleanup(capped_graph)
    end
    
    # Update knowledge base with capped version
    AriaTown.KnowledgeBase.set_graph(capped_graph)
    
    # Convert to JSON-LD with chibifire.com context
    context = AriaTown.ContextSchema.get_context()
    
    try do
      json_ld = RDF.JSON.LD.Encoder.encode!(capped_graph, context)
      formatted = Jason.encode!(json_ld, pretty: true)
      
      # Atomic write operation
      atomic_write(formatted)
      
      Logger.info("Saved NPC knowledge to chibifire schema at #{@knowledge_file}")
    rescue
      error ->
        Logger.error("Failed to save knowledge: #{inspect(error)}")
    end
  end
  
  defp atomic_write(content) do
    temp_file = @knowledge_file <> ".tmp"
    
    # Write to temporary file first
    File.write!(temp_file, content)
    
    # Create backup of current file
    if File.exists?(@knowledge_file) do
      backup_file = @backup_dir <> "#{Date.utc_today()}.jsonld"
      File.cp!(@knowledge_file, backup_file)
    end
    
    # Atomically replace the main file
    File.rename!(temp_file, @knowledge_file)
  end
  
  defp apply_memory_caps(graph) do
    npcs = get_all_npcs(graph)
    
    Enum.reduce(npcs, graph, fn npc, acc_graph ->
      acc_graph
      |> cap_conversations(npc, @max_conversations_per_npc)
      |> cap_knowledge_items(npc, @max_knowledge_items_per_npc)
      |> keep_recent_memories(npc, days: 7)
    end)
  end
  
  defp get_all_npcs(graph) do
    RDF.Graph.triples(graph)
    |> Enum.filter(fn {_s, p, o} -> 
      p == RDF.type() && o == AriaTown.ContextSchema.person()
    end)
    |> Enum.map(fn {s, _p, _o} -> s end)
  end
  
  defp cap_conversations(graph, npc, max_count) do
    conversations = get_npc_conversations(graph, npc)
    
    if length(conversations) > max_count do
      # Sort by timestamp, keep most recent
      sorted_conversations = Enum.sort_by(conversations, fn conv ->
        get_conversation_timestamp(graph, conv)
      end, {:desc, DateTime})
      
      recent_conversations = Enum.take(sorted_conversations, max_count)
      old_conversations = conversations -- recent_conversations
      
      # Remove old conversations from graph
      Enum.reduce(old_conversations, graph, fn conv, acc ->
        remove_conversation_triples(acc, conv)
      end)
    else
      graph
    end
  end
  
  defp cap_knowledge_items(graph, npc, max_count) do
    knowledge_items = get_npc_knowledge_triples(graph, npc)
    
    if length(knowledge_items) > max_count do
      # Keep most recent knowledge items
      sorted_items = Enum.sort_by(knowledge_items, fn {topic, timestamp} ->
        timestamp
      end, {:desc, DateTime})
      
      recent_items = Enum.take(sorted_items, max_count)
      old_items = knowledge_items -- recent_items
      
      # Remove old knowledge from graph
      Enum.reduce(old_items, graph, fn {topic, _timestamp}, acc ->
        RDF.Graph.delete(acc, {npc, AriaTown.ContextSchema.heard_about(), topic})
      end)
    else
      graph
    end
  end
  
  defp keep_recent_memories(graph, _npc, days: days) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)
    
    # Remove triples with timestamps older than cutoff
    RDF.Graph.triples(graph)
    |> Enum.filter(fn {_s, p, o} ->
      p == AriaTown.ContextSchema.timestamp() && 
      is_datetime_older?(o, cutoff_date)
    end)
    |> Enum.reduce(graph, fn {s, _p, _o}, acc ->
      remove_entity_triples(acc, s)
    end)
  end
  
  defp aggressive_cleanup(graph) do
    graph
    |> keep_recent_memories(nil, days: 3)      # Reduce to 3 days
    |> remove_low_importance_knowledge()       # Remove trivial facts
  end
  
  defp remove_low_importance_knowledge(graph) do
    # Remove knowledge about weather, routine activities
    low_importance_topics = [
      AriaTown.IRIHelpers.topic_iri("weather"),
      AriaTown.IRIHelpers.topic_iri("routine"),
      AriaTown.IRIHelpers.activity_iri("sleeping")
    ]
    
    Enum.reduce(low_importance_topics, graph, fn topic, acc ->
      RDF.Graph.triples(acc)
      |> Enum.filter(fn {_s, _p, o} -> o == topic end)
      |> Enum.reduce(acc, fn triple, inner_acc ->
        RDF.Graph.delete(inner_acc, triple)
      end)
    end)
  end
  
  defp estimated_size_mb(graph) do
    try do
      context = AriaTown.ContextSchema.get_context()
      json_size = graph 
        |> RDF.JSON.LD.Encoder.encode!(context)
        |> Jason.encode!()
        |> byte_size()
        
      json_size / (1024 * 1024)  # Convert to MB
    rescue
      _error -> 0.0  # Return 0 if estimation fails
    end
  end
  
  # Helper functions for extracting data from graph
  defp get_npc_conversations(graph, npc) do
    RDF.Graph.triples(graph)
    |> Enum.filter(fn {s, p, o} ->
      p == AriaTown.ContextSchema.participants() && o == npc
    end)
    |> Enum.map(fn {s, _p, _o} -> s end)
    |> Enum.uniq()
  end
  
  defp get_conversation_timestamp(graph, conversation) do
    case RDF.Graph.triples(graph)
         |> Enum.find(fn {s, p, _o} ->
           s == conversation && p == AriaTown.ContextSchema.timestamp()
         end) do
      {_s, _p, timestamp} -> timestamp
      nil -> DateTime.from_unix!(0)  # Default to epoch if no timestamp
    end
  end
  
  defp get_npc_knowledge_triples(graph, npc) do
    RDF.Graph.triples(graph)
    |> Enum.filter(fn {s, p, _o} ->
      s == npc && p == AriaTown.ContextSchema.heard_about()
    end)
    |> Enum.map(fn {_s, _p, topic} ->
      timestamp = get_topic_timestamp(graph, topic)
      {topic, timestamp}
    end)
  end
  
  defp get_topic_timestamp(graph, topic) do
    case RDF.Graph.triples(graph)
         |> Enum.find(fn {s, p, _o} ->
           s == topic && p == AriaTown.ContextSchema.timestamp()
         end) do
      {_s, _p, timestamp} -> timestamp
      nil -> DateTime.from_unix!(0)
    end
  end
  
  defp remove_conversation_triples(graph, conversation) do
    RDF.Graph.triples(graph)
    |> Enum.filter(fn {s, _p, _o} -> s == conversation end)
    |> Enum.reduce(graph, fn triple, acc ->
      RDF.Graph.delete(acc, triple)
    end)
  end
  
  defp remove_entity_triples(graph, entity) do
    RDF.Graph.triples(graph)
    |> Enum.filter(fn {s, _p, _o} -> s == entity end)
    |> Enum.reduce(graph, fn triple, acc ->
      RDF.Graph.delete(acc, triple)
    end)
  end
  
  defp is_datetime_older?(datetime_obj, cutoff_date) do
    case datetime_obj do
      %DateTime{} = dt -> DateTime.compare(dt, cutoff_date) == :lt
      _other -> false  # If not a DateTime, assume it's recent
    end
  end
end
