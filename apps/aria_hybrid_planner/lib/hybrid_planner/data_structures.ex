# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.DataStructures do
  @moduledoc "Encapsulated data structures with clean public interfaces.\nInternal structure is completely hidden from external access.\n"
  defmodule EncapsulatedPlan do
    @moduledoc "Opaque plan structure that hides internal solution tree complexity.\n\nThis provides a clean public interface while completely encapsulating\nthe internal Plan.solution_tree() structure.\n"
    @opaque t :: %__MODULE__{
              internal_plan: Plan.solution_tree(),
              metadata: map(),
              creation_time: DateTime.t(),
              temporal_validated: boolean()
            }
    defstruct [:internal_plan, :metadata, :creation_time, :temporal_validated]
    @doc "Create a new encapsulated plan from an internal solution tree.\n"
    @spec new(Plan.solution_tree(), map()) :: t()
    def new(internal_plan, metadata \\ %{}) do
      %__MODULE__{
        internal_plan: internal_plan,
        metadata: metadata,
        creation_time: DateTime.utc_now(),
        temporal_validated: false
      }
    end

    @doc "Create a temporally validated encapsulated plan.\n"
    @spec new_validated(Plan.solution_tree(), map()) :: t()
    def new_validated(internal_plan, metadata \\ %{}) do
      %__MODULE__{
        internal_plan: internal_plan,
        metadata: metadata,
        creation_time: DateTime.utc_now(),
        temporal_validated: true
      }
    end

    @doc "Get statistics about the plan without exposing internal structure.\n"
    @spec get_statistics(t()) :: map()
    def get_statistics(%__MODULE__{internal_plan: plan}) do
      Plan.Utils.tree_stats(plan)
    end

    @doc "Get the cost (number of primitive actions) of the plan.\n"
    @spec get_cost(t()) :: non_neg_integer()
    def get_cost(%__MODULE__{internal_plan: plan}) do
      Plan.Utils.plan_cost(plan)
    end

    @doc "Get the primitive actions from the plan.\n"
    @spec get_actions(t()) :: [Plan.plan_step()]
    def get_actions(%__MODULE__{internal_plan: plan}) do
      Plan.Utils.get_primitive_actions_dfs(plan)
    end

    @doc "Check if the plan has been temporally validated.\n"
    @spec temporally_validated?(t()) :: boolean()
    def temporally_validated?(%__MODULE__{temporal_validated: validated}) do
      validated
    end

    @doc "Get plan metadata.\n"
    @spec get_metadata(t()) :: map()
    def get_metadata(%__MODULE__{metadata: metadata}) do
      metadata
    end

    @doc "Get plan creation time.\n"
    @spec get_creation_time(t()) :: DateTime.t()
    def get_creation_time(%__MODULE__{creation_time: time}) do
      time
    end

    @doc "Mark plan as temporally validated.\n"
    @spec mark_temporally_validated(t()) :: t()
    def mark_temporally_validated(%__MODULE__{} = plan) do
      %{plan | temporal_validated: true}
    end

    @doc false
    @spec get_internal_plan(t()) :: Plan.solution_tree()
    def get_internal_plan(%__MODULE__{internal_plan: plan}) do
      plan
    end

    @doc false
    @spec update_internal_plan(t(), Plan.solution_tree()) :: t()
    def update_internal_plan(%__MODULE__{} = encapsulated_plan, new_internal_plan) do
      %{encapsulated_plan | internal_plan: new_internal_plan}
    end
  end

  defmodule PlanningContext do
    @moduledoc "Encapsulated planning context that separates planning state from world state.\n"
    @opaque t :: %__MODULE__{
              current_depth: integer(),
              max_depth: integer(),
              blacklisted_methods: MapSet.t(),
              planning_options: keyword(),
              verbose_level: integer()
            }
    defstruct [
      :current_depth,
      :max_depth,
      :blacklisted_methods,
      :planning_options,
      :verbose_level
    ]

    @doc "Create a new planning context.\n"
    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        current_depth: 0,
        max_depth: Keyword.get(opts, :max_depth, 100),
        blacklisted_methods: MapSet.new(),
        planning_options: opts,
        verbose_level: Keyword.get(opts, :verbose, 0)
      }
    end

    @doc "Increment the planning depth.\n"
    @spec increment_depth(t()) :: t()
    def increment_depth(%__MODULE__{current_depth: depth} = context) do
      %{context | current_depth: depth + 1}
    end

    @doc "Check if maximum depth has been reached.\n"
    @spec max_depth_reached?(t()) :: boolean()
    def max_depth_reached?(%__MODULE__{current_depth: current, max_depth: max}) do
      current >= max
    end

    @doc "Blacklist a method in this context.\n"
    @spec blacklist_method(t(), String.t()) :: t()
    def blacklist_method(%__MODULE__{blacklisted_methods: blacklisted} = context, method_name) do
      %{context | blacklisted_methods: MapSet.put(blacklisted, method_name)}
    end

    @doc "Check if a method is blacklisted.\n"
    @spec method_blacklisted?(t(), String.t()) :: boolean()
    def method_blacklisted?(%__MODULE__{blacklisted_methods: blacklisted}, method_name) do
      MapSet.member?(blacklisted, method_name)
    end

    @doc "Get the verbose level for logging.\n"
    @spec get_verbose_level(t()) :: integer()
    def get_verbose_level(%__MODULE__{verbose_level: level}) do
      level
    end

    @doc "Get planning options.\n"
    @spec get_options(t()) :: keyword()
    def get_options(%__MODULE__{planning_options: opts}) do
      opts
    end
  end
end
