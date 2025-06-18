defmodule NodeLibrary.KHRInteractivity.EventSystem do
  @moduledoc """
  KHR_interactivity Event System Nodes

  Implements event operations from the glTF KHR_interactivity specification:
  - khr_event_receive: Listen for events from the environment
  - khr_event_send: Emit events to other nodes or systems
  - khr_event_fire: Trigger immediate events within the graph
  - khr_event_filter: Filter events based on criteria
  - khr_event_queue: Queue events for delayed processing
  - khr_event_broadcast: Send events to multiple recipients

  Events enable reactive programming patterns and loose coupling between components.
  Events are stored in state and can trigger cascading behaviors.
  """

  alias StateV2
  alias Domain.Actions

  @doc "Register all event system actions with a domain"
  @spec register_actions(Domain.Core.t()) :: Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_event_receive, &event_receive/2, %{
      domain: "khr_interactivity",
      category: "event_system",
      khr_node_type: "event/receive",
      description: "Listen for events from the environment"
    })
    |> Actions.add_action(:khr_event_send, &event_send/2, %{
      domain: "khr_interactivity",
      category: "event_system",
      khr_node_type: "event/send",
      description: "Emit events to other nodes or systems"
    })
    |> Actions.add_action(:khr_event_fire, &event_fire/2, %{
      domain: "khr_interactivity",
      category: "event_system",
      khr_node_type: "event/fire",
      description: "Trigger immediate events within the graph"
    })
    |> Actions.add_action(:khr_event_filter, &event_filter/2, %{
      domain: "khr_interactivity",
      category: "event_system",
      khr_node_type: "event/filter",
      description: "Filter events based on criteria"
    })
    |> Actions.add_action(:khr_event_queue, &event_queue/2, %{
      domain: "khr_interactivity",
      category: "event_system",
      khr_node_type: "event/queue",
      description: "Queue events for delayed processing"
    })
    |> Actions.add_action(:khr_event_broadcast, &event_broadcast/2, %{
      domain: "khr_interactivity",
      category: "event_system",
      khr_node_type: "event/broadcast",
      description: "Send events to multiple recipients"
    })
  end

  @doc "Listen for events from the environment"
  def event_receive(state, [node_index, event_type]) when is_binary(event_type) do
    event_receive(state, [node_index, event_type, 0])
  end

  def event_receive(state, [node_index, event_type, timeout]) when is_binary(event_type) do
    # Check for pending events of the specified type
    event_queue = StateV2.get_fact(state, "event_system", "queue") || []
    
    case find_event_by_type(event_queue, event_type) do
      {:ok, event, remaining_queue} ->
        # Event found, remove from queue and return it
        state
        |> StateV2.set_fact("event_system", "queue", remaining_queue)
        |> StateV2.set_fact(Integer.to_string(node_index), "event", event)
        |> StateV2.set_fact(Integer.to_string(node_index), "received", true)
        
      :not_found ->
        # No event found, set up listener if timeout > 0
        if timeout > 0 do
          state
          |> StateV2.set_fact(Integer.to_string(node_index), "listening_for", event_type)
          |> StateV2.set_fact(Integer.to_string(node_index), "timeout", timeout)
          |> StateV2.set_fact(Integer.to_string(node_index), "received", false)
        else
          state
          |> StateV2.set_fact(Integer.to_string(node_index), "event", nil)
          |> StateV2.set_fact(Integer.to_string(node_index), "received", false)
        end
    end
  end

  def event_receive(state, [node_index, _event_type, _timeout]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "received", false)
  end

  @doc "Emit events to other nodes or systems"
  def event_send(state, [node_index, event_type, event_data]) when is_binary(event_type) do
    event_send(state, [node_index, event_type, event_data, "global"])
  end

  def event_send(state, [node_index, event_type, event_data, target]) when is_binary(event_type) do
    event = create_event(event_type, event_data, target)
    
    # Add event to the global event queue
    current_queue = StateV2.get_fact(state, "event_system", "queue") || []
    updated_queue = [event | current_queue]
    
    state
    |> StateV2.set_fact("event_system", "queue", updated_queue)
    |> StateV2.set_fact(Integer.to_string(node_index), "sent_event", event)
    |> StateV2.set_fact(Integer.to_string(node_index), "success", true)
  end

  def event_send(state, [node_index, _event_type, _event_data, _target]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "success", false)
  end

  @doc "Trigger immediate events within the graph"
  def event_fire(state, [node_index, event_type, event_data]) when is_binary(event_type) do
    event = create_event(event_type, event_data, "immediate")
    
    # Process immediate event (could trigger other nodes)
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "fired_event", event)
    |> StateV2.set_fact(Integer.to_string(node_index), "timestamp", System.system_time(:millisecond))
    |> process_immediate_event(event)
  end

  def event_fire(state, [node_index, _event_type, _event_data]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "success", false)
  end

  @doc "Filter events based on criteria"
  def event_filter(state, [node_index, source_events, filter_criteria]) when is_list(source_events) do
    filtered_events = Enum.filter(source_events, fn event ->
      matches_criteria?(event, filter_criteria)
    end)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "filtered_events", filtered_events)
    |> StateV2.set_fact(Integer.to_string(node_index), "original_count", length(source_events))
    |> StateV2.set_fact(Integer.to_string(node_index), "filtered_count", length(filtered_events))
  end

  def event_filter(state, [node_index, _source_events, _filter_criteria]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "filtered_events", [])
  end

  @doc "Queue events for delayed processing"
  def event_queue(state, [node_index, events]) when is_list(events) do
    event_queue(state, [node_index, events, 0])
  end

  def event_queue(state, [node_index, events, delay_ms]) when is_list(events) do
    timestamp = System.system_time(:millisecond)
    
    queued_events = Enum.map(events, fn event ->
      Map.merge(event, %{
        queued_at: timestamp,
        process_at: timestamp + delay_ms,
        status: "queued"
      })
    end)
    
    # Add to delayed processing queue
    current_delayed = StateV2.get_fact(state, "event_system", "delayed_queue") || []
    updated_delayed = queued_events ++ current_delayed
    
    state
    |> StateV2.set_fact("event_system", "delayed_queue", updated_delayed)
    |> StateV2.set_fact(Integer.to_string(node_index), "queued_events", queued_events)
    |> StateV2.set_fact(Integer.to_string(node_index), "delay_ms", delay_ms)
  end

  def event_queue(state, [node_index, _events, _delay_ms]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "queued_events", [])
  end

  @doc "Send events to multiple recipients"
  def event_broadcast(state, [node_index, event_type, event_data, recipients]) when is_binary(event_type) and is_list(recipients) do
    timestamp = System.system_time(:millisecond)
    
    broadcast_events = Enum.map(recipients, fn recipient ->
      create_event(event_type, event_data, recipient)
      |> Map.put(:broadcast_id, "#{node_index}_#{timestamp}")
    end)
    
    # Add all broadcast events to the queue
    current_queue = StateV2.get_fact(state, "event_system", "queue") || []
    updated_queue = broadcast_events ++ current_queue
    
    state
    |> StateV2.set_fact("event_system", "queue", updated_queue)
    |> StateV2.set_fact(Integer.to_string(node_index), "broadcast_events", broadcast_events)
    |> StateV2.set_fact(Integer.to_string(node_index), "recipient_count", length(recipients))
    |> StateV2.set_fact(Integer.to_string(node_index), "success", true)
  end

  def event_broadcast(state, [node_index, _event_type, _event_data, _recipients]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "success", false)
  end

  # Helper functions

  defp create_event(event_type, event_data, target) do
    %{
      type: event_type,
      data: event_data,
      target: target,
      timestamp: System.system_time(:millisecond),
      id: generate_event_id()
    }
  end

  defp generate_event_id do
    "evt_#{System.unique_integer([:positive])}"
  end

  defp find_event_by_type(event_queue, event_type) do
    case Enum.find_index(event_queue, fn event -> event.type == event_type end) do
      nil -> :not_found
      index ->
        event = Enum.at(event_queue, index)
        remaining_queue = List.delete_at(event_queue, index)
        {:ok, event, remaining_queue}
    end
  end

  defp matches_criteria?(event, criteria) do
    Enum.all?(criteria, fn {key, expected_value} ->
      Map.get(event, key) == expected_value
    end)
  end

  defp process_immediate_event(state, event) do
    # In a full implementation, this would trigger listening nodes
    # For now, just log the immediate event
    state
    |> StateV2.set_fact("event_system", "last_immediate_event", event)
  end

  @doc "Process delayed events (should be called periodically)"
  def process_delayed_events(state) do
    current_time = System.system_time(:millisecond)
    delayed_queue = StateV2.get_fact(state, "event_system", "delayed_queue") || []
    
    {ready_events, remaining_events} = Enum.split_with(delayed_queue, fn event ->
      event.process_at <= current_time
    end)
    
    # Move ready events to main queue
    if length(ready_events) > 0 do
      current_queue = StateV2.get_fact(state, "event_system", "queue") || []
      updated_queue = ready_events ++ current_queue
      
      state
      |> StateV2.set_fact("event_system", "queue", updated_queue)
      |> StateV2.set_fact("event_system", "delayed_queue", remaining_events)
      |> StateV2.set_fact("event_system", "processed_delayed_count", length(ready_events))
    else
      state
    end
  end
end
