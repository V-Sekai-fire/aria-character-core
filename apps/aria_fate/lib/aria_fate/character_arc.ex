# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaFate.CharacterArc do
  @moduledoc """
  Represents a planned character arc with episodes and story beats.

  This struct contains the results of character arc planning using the
  hybrid temporal planner, organizing story elements into episodes.
  """

  @type episode :: %{
          title: String.t(),
          description: String.t(),
          conflicts: [atom()],
          themes: [String.t()],
          character_growth: [String.t()],
          duration: integer()
        }

  @type t :: %__MODULE__{
          character_name: String.t(),
          episodes: [episode()],
          overall_theme: String.t(),
          character_growth_arc: [String.t()],
          planned_duration: integer(),
          created_at: DateTime.t()
        }

  defstruct [
    :character_name,
    episodes: [],
    overall_theme: "",
    character_growth_arc: [],
    planned_duration: 0,
    created_at: nil
  ]

  @doc """
  Creates a new character arc with default values.

  ## Examples

      iex> AriaFate.CharacterArc.new("Hero Name")
      %AriaFate.CharacterArc{
        character_name: "Hero Name",
        episodes: [],
        overall_theme: "",
        character_growth_arc: [],
        planned_duration: 0,
        created_at: nil
      }
  """
  def new(character_name, attrs \\ %{}) do
    attrs = Map.put(attrs, :character_name, character_name)
    attrs = Map.put_new(attrs, :created_at, DateTime.utc_now())
    struct(__MODULE__, attrs)
  end

  @doc """
  Adds an episode to the character arc.

  ## Examples

      iex> arc = AriaFate.CharacterArc.new("Hero")
      iex> episode = %{title: "The Beginning", conflicts: [:mystery], themes: ["discovery"]}
      iex> AriaFate.CharacterArc.add_episode(arc, episode)
      %AriaFate.CharacterArc{
        character_name: "Hero",
        episodes: [%{title: "The Beginning", conflicts: [:mystery], themes: ["discovery"]}]
      }
  """
  def add_episode(%__MODULE__{episodes: episodes} = arc, episode) do
    %{arc | episodes: episodes ++ [episode]}
  end

  @doc """
  Calculates the total planned duration of the character arc.
  """
  def total_duration(%__MODULE__{episodes: episodes}) do
    episodes
    |> Enum.map(&Map.get(&1, :duration, 1))
    |> Enum.sum()
  end

  @doc """
  Validates that a character arc has proper structure.
  """
  def validate(%__MODULE__{} = arc) do
    errors = []

    errors =
      if is_nil(arc.character_name) or arc.character_name == "",
        do: ["Character name is required" | errors],
        else: errors

    errors =
      if length(arc.episodes) == 0,
        do: ["At least one episode is required" | errors],
        else: errors

    case errors do
      [] -> {:ok, %{valid: true}}
      _ -> {:error, %{valid: false, errors: errors}}
    end
  end
end
