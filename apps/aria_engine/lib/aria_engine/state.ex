# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.State do
  @moduledoc """
  Represents domain state using predicate-subject-object triples with JSON-LD support.
  
  This module provides functionality to manage world state using RDF-like triples,
  where each fact is represented as {predicate, subject} -> object.
  
  State contains only domain facts - world conditions, entity properties, and relationships.
  Plans and solutions are managed separately by planning modules but can be bundled
  for export/debugging purposes.
  
  Supports JSON-LD serialization and deserialization with proper handling of lists
  and other data structures as specified in JSON-LD specification.
  
  Example:
  ```elixir
  state = AriaEngine.State.new()
  |> AriaEngine.State.set_object("location", "player", "room1")
  |> AriaEngine.State.set_object("inventory", "player", MapSet.new(["sword", "key"]))
  |> AriaEngine.State.set_object("health", "player", 100)
  |> AriaEngine.State.set_object("connected", "room1", ["room2", "room3"])
  
  AriaEngine.State.get_object(state, "location", "player")
  # => "room1"
  
  {:ok, json_ld} = AriaEngine.State.to_json_ld(state)
  {:ok, restored_state} = AriaEngine.State.from_json_ld(json_ld)
  ```
  """

  @type predicate :: String.t()
  @type subject :: String.t()
  @type object :: any()
  @type triple_key :: {predicate(), subject()}
  @type t :: %__MODULE__{
    data: %{triple_key() => object()},
    context: map()
  }

  defstruct data: %{}, context: %{
    "@context" => %{
      "@vocab" => "https://chibifire.com/vocab#",
      "temporal" => "https://chibifire.com/temporal#",
      "state" => "https://chibifire.com/state#",
      "timeline" => "https://chibifire.com/timeline#"
    }
  }

  @doc """
  Creates a new empty planning state.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Creates a new planning state from a map of predicate-subject-object data or a context map.
  """
  @spec new(map()) :: t()
  def new(%{"@context" => _} = context) when is_map(context) do
    %__MODULE__{context: context}
  end
  
  def new(data) when is_map(data) do
    %__MODULE__{data: data}
  end

  @doc """
  Gets the object for a given predicate and subject.
  Returns nil if the triple doesn't exist.
  """
  @spec get_object(t(), predicate(), subject()) :: object() | nil
  def get_object(%__MODULE__{data: data}, predicate, subject) do
    Map.get(data, {predicate, subject})
  end

  @doc """
  Sets the object for a given predicate and subject.
  """
  @spec set_object(t(), predicate(), subject(), object()) :: t()
  def set_object(%__MODULE__{data: data} = state, predicate, subject, object) do
    %{state | data: Map.put(data, {predicate, subject}, object)}
  end

  @doc """
  Removes a triple from the state.
  """
  @spec remove_object(t(), predicate(), subject()) :: t()
  def remove_object(%__MODULE__{data: data} = state, predicate, subject) do
    %{state | data: Map.delete(data, {predicate, subject})}
  end

  @doc """
  Checks if a subject has a given predicate with any object.
  """
  @spec has_subject?(t(), predicate(), subject()) :: boolean()
  def has_subject?(%__MODULE__{data: data}, predicate, subject) do
    Map.has_key?(data, {predicate, subject})
  end

  @doc """
  Checks if a subject variable exists in any predicate.
  """
  @spec has_subject_variable?(t(), subject()) :: boolean()
  def has_subject_variable?(%__MODULE__{data: data}, subject) do
    data
    |> Map.keys()
    |> Enum.any?(fn {_predicate, subj} -> subj == subject end)
  end

  @doc """
  Gets a list of all subjects that have properties.
  """
  @spec get_subjects(t()) :: [subject()]
  def get_subjects(%__MODULE__{data: data}) do
    data
    |> Map.keys()
    |> Enum.map(fn {_predicate, subject} -> subject end)
    |> Enum.uniq()
  end

  @doc """
  Gets all predicates for a given subject.
  """
  @spec get_subject_properties(t(), subject()) :: [predicate()]
  def get_subject_properties(%__MODULE__{data: data}, subject) do
    data
    |> Map.keys()
    |> Enum.filter(fn {_predicate, subj} -> subj == subject end)
    |> Enum.map(fn {predicate, _subj} -> predicate end)
  end

  @doc """
  Gets all triples as a list of {predicate, subject, object} tuples.
  """
  @spec to_triples(t()) :: [{predicate(), subject(), object()}]
  def to_triples(%__MODULE__{data: data}) do
    Enum.map(data, fn {{predicate, subject}, object} ->
      {predicate, subject, object}
    end)
  end

  @doc """
  Creates a state from a list of triples.
  """
  @spec from_triples([{predicate(), subject(), object()}]) :: t()
  def from_triples(triples) do
    data = 
      triples
      |> Enum.map(fn {predicate, subject, object} -> 
        {{predicate, subject}, object} 
      end)
      |> Map.new()
    
    %__MODULE__{data: data}
  end

  @doc """
  Merges two states, with the second state taking precedence for conflicts.
  """
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{data: data1}, %__MODULE__{data: data2}) do
    %__MODULE__{data: Map.merge(data1, data2)}
  end

  @doc """
  Returns a copy of the state with modified data.
  """
  @spec copy(t()) :: t()
  def copy(%__MODULE__{data: data}) do
    %__MODULE__{data: Map.new(data)}
  end

  @doc """
  Serializes the state to JSON-LD format with proper list handling.
  
  Objects that are Lists will be serialized as JSON-LD @list containers
  to preserve ordering for plans and sequences.
  """
  @spec to_json_ld(t()) :: {:ok, map()} | {:error, term()}
  def to_json_ld(%__MODULE__{data: data, context: context}) do
    try do
      json_ld = %{
        "@context" => context["@context"],
        "@type" => "AriaEngineState",
        "@id" => "_:state",
        "triples" => serialize_triples_to_json_ld(data)
      }
      
      {:ok, json_ld}
    rescue
      error -> {:error, {:serialization_error, error}}
    end
  end

  @doc """
  Deserializes JSON-LD format back to state with proper list handling.
  
  JSON-LD @list containers will be converted to Lists to maintain
  ordering for plans and action sequences.
  """
  @spec from_json_ld(map()) :: {:ok, t()} | {:error, term()}
  def from_json_ld(%{"@context" => context, "triples" => triples_data}) do
    try do
      data = deserialize_triples_from_json_ld(triples_data)
      
      state = %__MODULE__{
        data: data,
        context: %{"@context" => context}
      }
      
      {:ok, state}
    rescue
      error -> {:error, {:deserialization_error, error}}
    end
  end
  
  def from_json_ld(_invalid_json_ld) do
    {:error, :invalid_json_ld_format}
  end

  # Private functions for JSON-LD serialization
  defp serialize_triples_to_json_ld(data) do
    data
    |> Enum.map(fn {{predicate, subject}, object} ->
      %{
        "subject" => subject,
        "predicate" => predicate,
        "object" => serialize_object_to_json_ld(object)
      }
    end)
  end

  defp serialize_object_to_json_ld(list) when is_list(list) do
    %{
      "@list" => list
    }
  end

  defp serialize_object_to_json_ld(%MapSet{} = set) do
    %{
      "@set" => MapSet.to_list(set)
    }
  end

  defp serialize_object_to_json_ld(object) do
    object
  end

  # Private functions for JSON-LD deserialization
  defp deserialize_triples_from_json_ld(triples_data) do
    triples_data
    |> Enum.map(fn %{"subject" => subject, "predicate" => predicate, "object" => object} ->
      {{predicate, subject}, deserialize_object_from_json_ld(object)}
    end)
    |> Map.new()
  end

  defp deserialize_object_from_json_ld(%{"@set" => set_items}) do
    MapSet.new(set_items)
  end

  defp deserialize_object_from_json_ld(%{"@list" => list_items}) do
    list_items
  end

  defp deserialize_object_from_json_ld(object) do
    object
  end

  @doc """
  Adds an item to a set-type object. Creates a new MapSet if the object doesn't exist or isn't a set.
  """
  @spec add_to_set(t(), predicate(), subject(), any()) :: t()
  def add_to_set(%__MODULE__{data: data} = state, predicate, subject, item) do
    current_object = Map.get(data, {predicate, subject})
    
    new_set = case current_object do
      %MapSet{} = existing_set -> MapSet.put(existing_set, item)
      nil -> MapSet.new([item])
      _other -> MapSet.new([item])  # Replace non-set with new set
    end
    
    set_object(state, predicate, subject, new_set)
  end

  @doc """
  Removes an item from a set-type object.
  """
  @spec remove_from_set(t(), predicate(), subject(), any()) :: t()
  def remove_from_set(%__MODULE__{data: data} = state, predicate, subject, item) do
    current_object = Map.get(data, {predicate, subject})
    
    case current_object do
      %MapSet{} = existing_set ->
        new_set = MapSet.delete(existing_set, item)
        if MapSet.size(new_set) == 0 do
          remove_object(state, predicate, subject)
        else
          set_object(state, predicate, subject, new_set)
        end
      _other -> state  # No-op if not a set
    end
  end

  @doc """
  Appends an item to a list-type object. Creates a new list if the object doesn't exist or isn't a list.
  """
  @spec append_to_list(t(), predicate(), subject(), any()) :: t()
  def append_to_list(%__MODULE__{data: data} = state, predicate, subject, item) do
    current_object = Map.get(data, {predicate, subject})
    
    new_list = case current_object do
      list when is_list(list) -> list ++ [item]
      nil -> [item]
      _other -> [item]  # Replace non-list with new list
    end
    
    set_object(state, predicate, subject, new_list)
  end

  @doc """
  Prepends an item to a list-type object. Creates a new list if the object doesn't exist or isn't a list.
  """
  @spec prepend_to_list(t(), predicate(), subject(), any()) :: t()
  def prepend_to_list(%__MODULE__{data: data} = state, predicate, subject, item) do
    current_object = Map.get(data, {predicate, subject})
    
    new_list = case current_object do
      list when is_list(list) -> [item | list]
      nil -> [item]
      _other -> [item]  # Replace non-list with new list
    end
    
    set_object(state, predicate, subject, new_list)
  end

  @doc """
  Removes an item from a list-type object (removes first occurrence).
  """
  @spec remove_from_list(t(), predicate(), subject(), any()) :: t()
  def remove_from_list(%__MODULE__{data: data} = state, predicate, subject, item) do
    current_object = Map.get(data, {predicate, subject})
    
    case current_object do
      list when is_list(list) ->
        new_list = List.delete(list, item)
        if length(new_list) == 0 do
          remove_object(state, predicate, subject)
        else
          set_object(state, predicate, subject, new_list)
        end
      _other -> state  # No-op if not a list
    end
  end

  @doc """
  Checks if an object is a set (MapSet).
  """
  @spec is_set?(t(), predicate(), subject()) :: boolean()
  def is_set?(%__MODULE__{data: data}, predicate, subject) do
    case Map.get(data, {predicate, subject}) do
      %MapSet{} -> true
      _other -> false
    end
  end

  @doc """
  Checks if an object is a list.
  """
  @spec is_list?(t(), predicate(), subject()) :: boolean()
  def is_list?(%__MODULE__{data: data}, predicate, subject) do
    case Map.get(data, {predicate, subject}) do
      list when is_list(list) -> true
      _other -> false
    end
  end

  # Timeline serialization vocabulary using chibifire.com namespace
  @timeline_context %{
    "@context" => %{
      "@vocab" => "https://chibifire.com/vocab#",
      "temporal" => "https://chibifire.com/temporal#",
      "state" => "https://chibifire.com/state#",
      "timeline" => "https://chibifire.com/timeline#",
      "timestamp" => "timeline:timestamp",
      "duration" => "timeline:duration",
      "sequence" => "timeline:sequence",
      "parallel" => "timeline:parallel",
      "action" => "timeline:action",
      "event" => "timeline:event"
    }
  }

  @doc """
  Serializes state with timeline-specific context for temporal planning.
  
  Includes specialized vocabulary for timeline events, sequences, and temporal relationships.
  """
  @spec to_timeline_json_ld(t()) :: {:ok, map()} | {:error, term()}
  def to_timeline_json_ld(%__MODULE__{data: data}) do
    try do
      json_ld = %{
        "@context" => @timeline_context["@context"],
        "@type" => "AriaEngineTemporalState",
        "@id" => "_:temporal_state",
        "timeline:triples" => serialize_triples_to_json_ld(data),
        "temporal:context" => extract_temporal_context(data)
      }
      
      {:ok, json_ld}
    rescue
      error -> {:error, {:timeline_serialization_error, error}}
    end
  end

  @doc """
  Deserializes timeline-specific JSON-LD back to state.
  """
  @spec from_timeline_json_ld(map()) :: {:ok, t()} | {:error, term()}
  def from_timeline_json_ld(%{"timeline:triples" => triples_data} = _json_ld) do
    try do
      data = deserialize_triples_from_json_ld(triples_data)
      
      state = %__MODULE__{
        data: data,
        context: @timeline_context
      }
      
      {:ok, state}
    rescue
      error -> {:error, {:timeline_deserialization_error, error}}
    end
  end
  
  def from_timeline_json_ld(_invalid_json_ld) do
    {:error, :invalid_timeline_json_ld_format}
  end

  # Extract temporal relationships from state data
  defp extract_temporal_context(data) do
    temporal_facts = data
    |> Enum.filter(fn {{predicate, _subject}, _object} ->
      String.starts_with?(predicate, "temporal:") or 
      String.starts_with?(predicate, "timeline:")
    end)
    |> Enum.map(fn {{predicate, subject}, object} ->
      %{
        "subject" => subject,
        "predicate" => predicate,
        "object" => serialize_object_to_json_ld(object)
      }
    end)
    
    %{
      "temporal:facts" => temporal_facts,
      "timeline:created" => DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc """
  Creates a plan structure with both sequential and parallel tasks.
  
  Plans can contain:
  - Sequential tasks: [{task, args}, {task, args}, ...]
  - Parallel task sets: {:parallel, [task1, task2, task3]}
  - Mixed structures: [task1, {:parallel, [task2, task3]}, task4]
  
  Example:
  ```elixir
  plan = [
    {"move", ["alex", {5, 5}]},
    {:parallel, [
      {"scout", ["maya", "north"]},
      {"scout", ["alex", "south"]},
      {"analyze", ["jordan", "patterns"]}
    ]},
    {"coordinate", ["all_agents"]}
  ]
  
  state = AriaEngine.State.set_plan(state, "mission_1", plan)
  ```
  """
  @spec set_plan(t(), String.t(), list()) :: t()
  def set_plan(%__MODULE__{} = state, plan_id, plan) when is_list(plan) do
    set_object(state, "plan", plan_id, normalize_plan_structure(plan))
  end

  @doc """
  Gets a plan by ID, preserving parallel task structure.
  """
  @spec get_plan(t(), String.t()) :: list() | nil
  def get_plan(%__MODULE__{} = state, plan_id) do
    get_object(state, "plan", plan_id)
  end

  @doc """
  Adds a set of independent tasks that can be solved in parallel.
  
  This is useful for representing tasks that have no dependencies on each other
  and can be executed concurrently by different agents or systems.
  
  Example:
  ```elixir
  independent_tasks = [
    {"scout", ["maya", "area_1"]},
    {"scout", ["alex", "area_2"]}, 
    {"analyze", ["jordan", "historical_data"]}
  ]
  
  state = AriaEngine.State.add_parallel_tasks(state, "scouting_phase", independent_tasks)
  ```
  """
  @spec add_parallel_tasks(t(), String.t(), list()) :: t()
  def add_parallel_tasks(%__MODULE__{} = state, task_set_id, tasks) when is_list(tasks) do
    parallel_structure = {:parallel, tasks}
    set_object(state, "task_set", task_set_id, parallel_structure)
  end

  @doc """
  Gets independent tasks that can be solved in parallel.
  """
  @spec get_parallel_tasks(t(), String.t()) :: {:parallel, list()} | nil
  def get_parallel_tasks(%__MODULE__{} = state, task_set_id) do
    get_object(state, "task_set", task_set_id)
  end

  @doc """
  Creates a goal-task network with both sequential and parallel structures.
  
  Supports complex planning structures where some tasks must be sequential
  while others can be executed independently.
  
  Example:
  ```elixir
  gtn = %{
    "phases" => [
      %{
        "name" => "reconnaissance", 
        "type" => "parallel",
        "tasks" => [
          {"scout", ["maya", "patrol_route"]},
          {"analyze", ["alex", "enemy_patterns"]}
        ]
      },
      %{
        "name" => "coordination",
        "type" => "sequential", 
        "tasks" => [
          {"coordinate", ["maya", "alex"]},
          {"execute", ["maya", "elimination_plan"]}
        ]
      }
    ]
  }
  
  state = AriaEngine.State.set_goal_task_network(state, "mission_gtn", gtn)
  ```
  """
  @spec set_goal_task_network(t(), String.t(), map()) :: t()
  def set_goal_task_network(%__MODULE__{} = state, gtn_id, gtn) when is_map(gtn) do
    normalized_gtn = normalize_goal_task_network(gtn)
    set_object(state, "goal_task_network", gtn_id, normalized_gtn)
  end

  @doc """
  Gets a goal-task network by ID.
  """
  @spec get_goal_task_network(t(), String.t()) :: map() | nil
  def get_goal_task_network(%__MODULE__{} = state, gtn_id) do
    get_object(state, "goal_task_network", gtn_id)
  end

  @doc """
  Extracts all parallel task sets from a plan or goal-task network.
  
  This is useful for identifying which tasks can be solved independently
  and potentially distributed across multiple planning agents.
  """
  @spec extract_parallel_tasks(list() | map()) :: [list()]
  def extract_parallel_tasks(structure) when is_list(structure) do
    structure
    |> Enum.flat_map(&extract_parallel_from_item/1)
  end

  def extract_parallel_tasks(%{"phases" => phases}) when is_list(phases) do
    phases
    |> Enum.filter(fn phase -> Map.get(phase, "type") == "parallel" end)
    |> Enum.map(fn phase -> Map.get(phase, "tasks", []) end)
  end

  def extract_parallel_tasks(_), do: []

  @doc """
  Checks if a task structure contains any parallel tasks.
  """
  @spec has_parallel_tasks?(list() | map()) :: boolean()
  def has_parallel_tasks?(structure) do
    length(extract_parallel_tasks(structure)) > 0
  end

  # Private helper functions

  defp normalize_plan_structure(plan) when is_list(plan) do
    Enum.map(plan, &normalize_plan_item/1)
  end

  defp normalize_plan_item({:parallel, tasks}) when is_list(tasks) do
    %{"@type" => "ParallelTaskSet", "tasks" => tasks}
  end

  defp normalize_plan_item(task) when is_tuple(task) do
    task
  end

  defp normalize_plan_item(item), do: item

  defp normalize_goal_task_network(%{"phases" => phases} = gtn) when is_list(phases) do
    normalized_phases = Enum.map(phases, &normalize_gtn_phase/1)
    Map.put(gtn, "phases", normalized_phases)
  end

  defp normalize_goal_task_network(gtn), do: gtn

  defp normalize_gtn_phase(%{"type" => "parallel", "tasks" => tasks} = phase) do
    normalized_tasks = %{"@type" => "ParallelTaskSet", "tasks" => tasks}
    Map.put(phase, "tasks", normalized_tasks)
  end

  defp normalize_gtn_phase(phase), do: phase

  defp extract_parallel_from_item({:parallel, tasks}) when is_list(tasks) do
    [tasks]
  end

  defp extract_parallel_from_item(%{"@type" => "ParallelTaskSet", "tasks" => tasks}) do
    [tasks]
  end

  defp extract_parallel_from_item(_), do: []

  # Domain state helper functions

  @doc """
  Adds a domain fact to the state.
  Facts represent world conditions, entity properties, and relationships.
  
  Examples:
    add_domain_fact(state, "can_move", "player", true)
    add_domain_fact(state, "has_item", "player", "sword")
    add_domain_fact(state, "connected", "room1", ["room2", "room3"])
  """
  @spec add_domain_fact(t(), predicate(), subject(), object()) :: t()
  def add_domain_fact(state, predicate, subject, object) do
    set_object(state, predicate, subject, object)
  end

  @doc """
  Queries domain facts from the RDF triple store.
  """
  @spec query_domain_fact(t(), predicate(), subject()) :: object() | nil
  def query_domain_fact(state, predicate, subject) do
    get_object(state, predicate, subject)
  end

  @doc """
  Gets all facts about a specific subject (entity).
  Returns a map of predicate -> object pairs.
  """
  @spec get_entity_facts(t(), subject()) :: map()
  def get_entity_facts(%__MODULE__{data: data}, subject) do
    data
    |> Enum.filter(fn {{_predicate, s}, _object} -> s == subject end)
    |> Enum.into(%{}, fn {{predicate, _subject}, object} -> {predicate, object} end)
  end

  @doc """
  Gets all subjects that have a specific predicate-object relationship.
  """
  @spec find_subjects_with(t(), predicate(), object()) :: list(subject())
  def find_subjects_with(%__MODULE__{data: data}, predicate, object) do
    data
    |> Enum.filter(fn {{p, _subject}, obj} -> p == predicate and obj == object end)
    |> Enum.map(fn {{_predicate, subject}, _object} -> subject end)
  end

  @doc """
  Removes a domain fact from the state.
  """
  @spec remove_domain_fact(t(), predicate(), subject()) :: t()
  def remove_domain_fact(%__MODULE__{data: data, context: context}, predicate, subject) do
    new_data = Map.delete(data, {predicate, subject})
    %__MODULE__{data: new_data, context: context}
  end

  @doc """
  Checks if a domain fact exists in the state.
  """
  @spec has_domain_fact?(t(), predicate(), subject()) :: boolean()
  def has_domain_fact?(%__MODULE__{data: data}, predicate, subject) do
    Map.has_key?(data, {predicate, subject})
  end
end
