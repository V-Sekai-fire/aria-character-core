defmodule TestModule do
  @type state :: AriaEngine.StateV2.t()
  @type goal :: {String.t(), String.t(), AriaEngine.StateV2.fact_value()}
  @type action_fn :: (AriaEngine.StateV2.t(), list() -> AriaEngine.StateV2.t() | false)

  alias AriaEngine.StateV2

  def create_state(data) do
    %StateV2{entities: data}
  end

  def update_state(state, field, value) do
    StateV2.put(state, field, value)
  end

  def process_with_full_name(data) do
    state = %AriaEngine.StateV2{entities: data}
    AriaEngine.StateV2.update(state, :status, :active)
  end
end
