defmodule AriaEngine.Timeline.Bridge do
  @moduledoc "Represents a bridge point in a Timeline where execution can pause, make decisions, or branch.\n\nBridges are temporal points that create segmentation boundaries in timelines,\nallowing for decision points, conditional execution, resource synchronization,\nand other control flow operations within temporal planning.\n\nAll bridge positions use DateTime with timezone information to maintain\nconsistency with the Timeline system's temporal model.\n\n## Bridge Types\n\n- `:decision` - Decision points where execution can branch based on conditions\n- `:condition` - Conditional checks that may block or redirect execution\n- `:synchronization` - Points where multiple timelines must synchronize\n- `:resource_check` - Resource availability validation points\n\n## Examples\n\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"route_decision\",\n    ...>   DateTime.utc_now(),\n    ...>   :decision,\n    ...>   metadata: %{options: [\"north\", \"south\"]}\n    ...> )\n    iex> bridge.type\n    :decision\n\n"
  @type id :: String.t()
  @type bridge_type :: :decision | :condition | :synchronization | :resource_check
  @type t :: %__MODULE__{id: id(), position: DateTime.t(), type: bridge_type(), metadata: map()}
  defstruct id: nil, position: nil, type: :decision, metadata: %{}

  @doc "Creates a new bridge with the specified parameters.\n\n## Parameters\n\n- `id` - Unique identifier for the bridge\n- `position` - DateTime when the bridge occurs (must have timezone)\n- `type` - Type of bridge operation\n- `opts` - Additional options including metadata\n\n## Examples\n\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> bridge.id\n    \"decision_1\"\n\n"
  @spec new(id(), DateTime.t(), bridge_type(), keyword()) :: t()
  def new(id, %DateTime{} = position, type, opts \\ []) do
    validate_bridge_type!(type)
    metadata = Keyword.get(opts, :metadata, %{})
    %__MODULE__{id: id, position: position, type: type, metadata: metadata}
  end

  @doc "Validates that a bridge type is supported.\n\n## Examples\n\n    iex> AriaEngine.Timeline.Bridge.valid_type?(:decision)\n    true\n\n    iex> AriaEngine.Timeline.Bridge.valid_type?(:invalid)\n    false\n\n"
  @spec valid_type?(atom()) :: boolean()
  def valid_type?(type) do
    type in [:decision, :condition, :synchronization, :resource_check]
  end

  @doc "Checks if a bridge is a decision point.\n\n## Examples\n\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"test\", DateTime.utc_now(), :decision)\n    iex> AriaEngine.Timeline.Bridge.decision?(bridge)\n    true\n\n"
  @spec decision?(t()) :: boolean()
  def decision?(%__MODULE__{type: :decision}) do
    true
  end

  def decision?(%__MODULE__{}) do
    false
  end

  @doc "Checks if a bridge is a condition check.\n\n## Examples\n\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"test\", DateTime.utc_now(), :condition)\n    iex> AriaEngine.Timeline.Bridge.condition?(bridge)\n    true\n\n"
  @spec condition?(t()) :: boolean()
  def condition?(%__MODULE__{type: :condition}) do
    true
  end

  def condition?(%__MODULE__{}) do
    false
  end

  @doc "Checks if a bridge is a synchronization point.\n\n## Examples\n\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"test\", DateTime.utc_now(), :synchronization)\n    iex> AriaEngine.Timeline.Bridge.synchronization?(bridge)\n    true\n\n"
  @spec synchronization?(t()) :: boolean()
  def synchronization?(%__MODULE__{type: :synchronization}) do
    true
  end

  def synchronization?(%__MODULE__{}) do
    false
  end

  @doc "Checks if a bridge is a resource check point.\n\n## Examples\n\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"test\", DateTime.utc_now(), :resource_check)\n    iex> AriaEngine.Timeline.Bridge.resource_check?(bridge)\n    true\n\n"
  @spec resource_check?(t()) :: boolean()
  def resource_check?(%__MODULE__{type: :resource_check}) do
    true
  end

  def resource_check?(%__MODULE__{}) do
    false
  end

  @doc "Updates bridge metadata.\n\n## Examples\n\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"test\", DateTime.utc_now(), :decision)\n    iex> updated = AriaEngine.Timeline.Bridge.update_metadata(bridge, %{priority: :high})\n    iex> updated.metadata.priority\n    :high\n\n"
  @spec update_metadata(t(), map()) :: t()
  def update_metadata(%__MODULE__{} = bridge, new_metadata) do
    %{bridge | metadata: Map.merge(bridge.metadata, new_metadata)}
  end

  @doc "Checks if a bridge occurs before a given DateTime.\n\n## Examples\n\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"test\", position, :decision)\n    iex> check_time = DateTime.from_naive!(~N[2025-01-01 13:00:00], \"Etc/UTC\")\n    iex> AriaEngine.Timeline.Bridge.before?(bridge, check_time)\n    true\n\n"
  @spec before?(t(), DateTime.t()) :: boolean()
  def before?(%__MODULE__{position: position}, %DateTime{} = check_time) do
    DateTime.compare(position, check_time) == :lt
  end

  @doc "Checks if a bridge occurs after a given DateTime.\n\n## Examples\n\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"test\", position, :decision)\n    iex> check_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> AriaEngine.Timeline.Bridge.after?(bridge, check_time)\n    true\n\n"
  @spec after?(t(), DateTime.t()) :: boolean()
  def after?(%__MODULE__{position: position}, %DateTime{} = check_time) do
    DateTime.compare(position, check_time) == :gt
  end

  @doc "Checks if a bridge occurs at exactly the given DateTime.\n\n## Examples\n\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"test\", position, :decision)\n    iex> AriaEngine.Timeline.Bridge.at?(bridge, position)\n    true\n\n"
  @spec at?(t(), DateTime.t()) :: boolean()
  def at?(%__MODULE__{position: position}, %DateTime{} = check_time) do
    DateTime.compare(position, check_time) == :eq
  end

  @doc "Sorts bridges by their temporal position.\n\n## Examples\n\n    iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge1 = AriaEngine.Timeline.Bridge.new(\"b1\", pos1, :decision)\n    iex> bridge2 = AriaEngine.Timeline.Bridge.new(\"b2\", pos2, :decision)\n    iex> [sorted1, _sorted2] = AriaEngine.Timeline.Bridge.sort_by_position([bridge2, bridge1])\n    iex> sorted1.id\n    \"b1\"\n\n"
  @spec sort_by_position([t()]) :: [t()]
  def sort_by_position(bridges) when is_list(bridges) do
    Enum.sort(bridges, fn bridge1, bridge2 ->
      DateTime.compare(bridge1.position, bridge2.position) != :gt
    end)
  end

  @doc "Finds bridges within a time range.\n\n## Examples\n\n    iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], \"Etc/UTC\")\n    iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> pos2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], \"Etc/UTC\")\n    iex> bridge1 = AriaEngine.Timeline.Bridge.new(\"b1\", pos1, :decision)\n    iex> bridge2 = AriaEngine.Timeline.Bridge.new(\"b2\", pos2, :decision)\n    iex> bridges = AriaEngine.Timeline.Bridge.in_range([bridge1, bridge2], start_time, end_time)\n    iex> length(bridges)\n    1\n\n"
  @spec in_range([t()], DateTime.t(), DateTime.t()) :: [t()]
  def in_range(bridges, %DateTime{} = start_time, %DateTime{} = end_time) when is_list(bridges) do
    Enum.filter(bridges, fn bridge ->
      DateTime.compare(bridge.position, start_time) != :lt and
        DateTime.compare(bridge.position, end_time) != :gt
    end)
  end

  defp validate_bridge_type!(type) do
    unless valid_type?(type) do
      raise ArgumentError,
            "Invalid bridge type: #{inspect(type)}. Must be one of: :decision, :condition, :synchronization, :resource_check"
    end
  end
end