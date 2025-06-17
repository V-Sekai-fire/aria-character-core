defmodule Mix.Tasks.AriaEngine.Benchmark.Satellite.DomainBuilder.Actions do
  @moduledoc "Handles adding durative actions to the AriaEngine Domain."

  alias AriaEngine.Domain
  alias AriaEngine.State
  alias AriaEngine.SatelliteActions
  # Removed alias AriaEngine.PddlParser

  @type parsed_domain_map :: AriaEngine.PddlParser.parsed_domain_map()
  @type initial_state :: AriaEngine.State.t()

  @spec add_durative_actions(AriaEngine.Domain.Core.t(), parsed_domain_map(), initial_state()) :: AriaEngine.Domain.Core.t()
  def add_durative_actions(domain, parsed_domain, initial_state) do
    Enum.reduce(parsed_domain.durative_actions, domain, fn action, acc_domain ->
      action_fn = case action.name do
        :turn_to -> &SatelliteActions.turn_to/2
        :switch_on -> &SatelliteActions.switch_on/2
        :switch_off -> &SatelliteActions.switch_off/2
        :calibrate -> &SatelliteActions.calibrate/2
        :take_image -> &SatelliteActions.take_image/2
        _ -> fn state, _args -> state end # Default no-op
      end

      # Determine duration based on parsed PDDL and initial state fluents
      duration_metadata = case action.duration do
        {:turn_time, arg1, arg2} ->
          # Lookup turn-time from initial_state
          key = "turn-time"
          subject = "#{Atom.to_string(arg1)}_#{Atom.to_string(arg2)}"
          value = State.get_fact(initial_state, key, subject)
          %{duration: {value, value}} # Fixed duration for now
        {:calibration_time, arg} ->
          # Lookup calibration-time from initial_state
          key = "calibration-time"
          subject = Atom.to_string(arg)
          value = State.get_fact(initial_state, key, subject)
          %{duration: {value, value}} # Fixed duration for now
        duration_val when is_integer(duration_val) ->
          %{duration: {duration_val, duration_val}}
        _ ->
          # Default duration if not specified or complex
          %{duration: {1, 5}}
      end

      Domain.add_action(acc_domain, action.name, action_fn, duration_metadata)
    end)
  end
end
