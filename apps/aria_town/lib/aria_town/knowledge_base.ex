defmodule AriaTown.KnowledgeBase do
  @moduledoc """
  RDF-based knowledge representation for NPC memories, relationships, and conversations.
  Uses chibifire.com namespace for semantic web compatibility.
  """
  
  use Agent
  require Logger
  
  alias RDF.Graph
  
  def start_link(_) do
    Agent.start_link(fn -> Graph.new() end, name: __MODULE__)
  end
  
  def get_graph() do
    Agent.get(__MODULE__, & &1)
  end
  
  def set_graph(graph) do
    Agent.put(__MODULE__, fn _ -> graph end)
  end
  
  def add_triple(subject, predicate, object) do
    Agent.update(__MODULE__, fn graph ->
      Graph.add(graph, {subject, predicate, object})
    end)
  end
  
  def add_triples(triples) when is_list(triples) do
    Agent.update(__MODULE__, fn graph ->
      Enum.reduce(triples, graph, fn triple, acc_graph ->
        Graph.add(acc_graph, triple)
      end)
    end)
  end
  
  def query_sparql(query_string) do
    graph = get_graph()
    case SPARQL.Query.execute(query_string, graph) do
      {:ok, results} -> results
      {:error, reason} -> 
        Logger.error("SPARQL query failed: #{reason}")
        []
    end
  end
  
  # NPC Helper Functions
  def add_npc(npc_id, personality, location) do
    npc_iri = AriaTown.IRIHelpers.npc_iri(npc_id)
    location_iri = AriaTown.IRIHelpers.location_iri(location)
    
    add_triples([
      {npc_iri, RDF.type(), AriaTown.ContextSchema.person()},
      {npc_iri, AriaTown.ContextSchema.personality(), personality},
      {npc_iri, AriaTown.ContextSchema.located_at(), location_iri}
    ])
  end
  
  def add_conversation(npc1, npc2, topic, content) do
    conversation_id = UUID.uuid4()
    conversation_iri = AriaTown.IRIHelpers.conversation_iri(conversation_id)
    npc1_iri = AriaTown.IRIHelpers.npc_iri(npc1)
    npc2_iri = AriaTown.IRIHelpers.npc_iri(npc2)
    topic_iri = AriaTown.IRIHelpers.topic_iri(topic)
    
    add_triples([
      {conversation_iri, RDF.type(), AriaTown.ContextSchema.conversation()},
      {conversation_iri, AriaTown.ContextSchema.participants(), npc1_iri},
      {conversation_iri, AriaTown.ContextSchema.participants(), npc2_iri},
      {conversation_iri, AriaTown.ContextSchema.about(), topic_iri},
      {conversation_iri, AriaTown.ContextSchema.content(), content},
      {conversation_iri, AriaTown.ContextSchema.timestamp(), DateTime.utc_now()},
      {npc1_iri, AriaTown.ContextSchema.spoke_with(), npc2_iri},
      {npc2_iri, AriaTown.ContextSchema.spoke_with(), npc1_iri}
    ])
    
    conversation_id
  end
  
  def add_knowledge(npc_id, topic, source \\ nil) do
    npc_iri = AriaTown.IRIHelpers.npc_iri(npc_id)
    topic_iri = AriaTown.IRIHelpers.topic_iri(topic)
    
    triples = [
      {npc_iri, AriaTown.ContextSchema.heard_about(), topic_iri},
      {topic_iri, AriaTown.ContextSchema.timestamp(), DateTime.utc_now()}
    ]
    
    triples = if source do
      source_iri = AriaTown.IRIHelpers.npc_iri(source)
      [{topic_iri, AriaTown.ContextSchema.source(), source_iri} | triples]
    else
      triples
    end
    
    add_triples(triples)
  end
  
  def get_npc_knowledge(npc_id) do
    npc_iri = AriaTown.IRIHelpers.npc_iri(npc_id)
    
    query = """
    SELECT ?topic WHERE {
      <#{npc_iri}> <#{AriaTown.ContextSchema.heard_about()}> ?topic .
    }
    """
    
    query_sparql(query)
    |> Enum.map(fn %{"topic" => topic} -> topic end)
  end
  
  def get_shared_knowledge(npc1, npc2) do
    npc1_knowledge = get_npc_knowledge(npc1) |> MapSet.new()
    npc2_knowledge = get_npc_knowledge(npc2) |> MapSet.new()
    
    MapSet.intersection(npc1_knowledge, npc2_knowledge)
    |> MapSet.to_list()
  end
  
  def update_npc_location(npc_id, new_location) do
    npc_iri = AriaTown.IRIHelpers.npc_iri(npc_id)
    location_iri = AriaTown.IRIHelpers.location_iri(new_location)
    
    # Remove old location
    Agent.update(__MODULE__, fn graph ->
      # Find and remove existing location triples
      existing_locations = Graph.triples(graph)
      |> Enum.filter(fn {s, p, _o} -> 
        s == npc_iri && p == AriaTown.ContextSchema.located_at()
      end)
      
      # Remove old locations and add new one
      updated_graph = Enum.reduce(existing_locations, graph, fn triple, acc ->
        Graph.delete(acc, triple)
      end)
      
      Graph.add(updated_graph, {npc_iri, AriaTown.ContextSchema.located_at(), location_iri})
    end)
  end
  
  def update_npc_activity(npc_id, activity) do
    npc_iri = AriaTown.IRIHelpers.npc_iri(npc_id)
    activity_iri = AriaTown.IRIHelpers.activity_iri(activity)
    
    add_triple(npc_iri, AriaTown.ContextSchema.engaged_in(), activity_iri)
  end
end
