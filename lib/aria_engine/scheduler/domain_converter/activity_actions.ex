defmodule AriaEngine.Scheduler.DomainConverter.ActivityActions do
  @moduledoc "Creates basic activity actions for the domain.\n\nThis module handles the creation of durative actions for activities,\nconverting activity definitions into executable domain actions with\nproper resource allocation and temporal constraints.\n"
  require Logger
  alias AriaEngine.Scheduler.{Entity, Resource}
  @type activity :: map()
  @type duration_value :: map() | binary() | number()
  @doc "Create basic activity actions for the domain.\nAll actions are now durative actions; \"instantaneous\" actions are durative actions with duration 0.\n"
  @spec create_basic_activity_actions([activity()], [Entity.t()], [Resource.t()]) :: %{
          atom() => function()
        }
  def create_basic_activity_actions(activities, entities, resources) do
    activities
    |> Enum.map(fn activity ->
      durative_action_name = String.to_atom("durative_#{activity["id"]}")
      durative_action_fn = create_durative_activity_action(activity, entities, resources)
      {durative_action_name, durative_action_fn}
    end)
    |> Enum.into(%{})
  end

  @doc "Create durative action function for a specific activity.\n"
  @spec create_durative_activity_action(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_durative_activity_action(activity, _entities, _resources) do
    fn state, _args ->
      activity_id = activity["id"]
      duration_val = Map.get(activity, :duration)
      duration = parse_duration(duration_val)
      required_resources = Map.get(activity, :required_resources, [])

      updated_state =
        state
        |> AriaEngine.State.set_fact(activity_id, "status", "in_progress")
        |> AriaEngine.State.set_fact(activity_id, "start_time", DateTime.utc_now())
        |> AriaEngine.State.set_fact(activity_id, "duration", duration)

      final_state =
        Enum.reduce(required_resources, updated_state, fn resource_id, acc_state ->
          current_usage = AriaEngine.State.get_fact(acc_state, resource_id, "current_usage") || 0

          acc_state
          |> AriaEngine.State.set_fact(resource_id, "current_usage", current_usage + 1)
          |> AriaEngine.State.set_fact(resource_id, "allocated_to", activity_id)
        end)

      final_state
      |> AriaEngine.State.set_fact(activity_id, "completed", true)
      |> AriaEngine.State.set_fact(activity_id, "status", "completed")
      |> AriaEngine.State.set_fact(activity_id, "end_time", DateTime.utc_now())
    end
  end

  @doc "Parse duration value into a standardized format.\n"
  @spec parse_duration(duration_value()) :: map() | nil
  def parse_duration(duration_val) do
    cond do
      is_map(duration_val) and
          (Map.has_key?(duration_val, "start") or Map.has_key?(duration_val, "end")) ->
        duration_val

      is_map(duration_val) and
          (Map.has_key?(duration_val, :start) or Map.has_key?(duration_val, :end)) ->
        duration_val

      is_map(duration_val) ->
        duration_val

      is_binary(duration_val) ->
        case :iso8601.parse_duration(String.to_charlist(duration_val)) do
          parsed when is_list(parsed) ->
            _keys = [:years, :months, :days, :hours, :minutes, :seconds]
            map = Enum.into(parsed, %{})

            %{
              years: Map.get(map, :years, 0),
              months: Map.get(map, :months, 0),
              days: Map.get(map, :days, 0),
              hours: Map.get(map, :hours, 0),
              minutes: Map.get(map, :minutes, 0),
              seconds: Map.get(map, :seconds, 0)
            }

          _ ->
            nil
        end

      true ->
        nil
    end
  end
end