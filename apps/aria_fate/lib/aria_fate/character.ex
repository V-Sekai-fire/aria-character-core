# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaFate.Character do
  @moduledoc """
  Represents a Fate Core character with all standard character sheet elements.

  This struct follows the Fate Core character creation rules and includes
  all necessary fields for a complete character sheet.
  """

  @type aspect :: String.t()
  @type skill_rating :: 0..8
  @type stress_track :: %{physical: integer(), mental: integer()}
  @type consequence :: %{mild: String.t() | nil, moderate: String.t() | nil, severe: String.t() | nil}

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          high_concept: aspect(),
          trouble: aspect(),
          aspects: [aspect()],
          skills: %{atom() => skill_rating()},
          stunts: [String.t()],
          refresh: integer(),
          fate_points: integer(),
          stress_tracks: stress_track(),
          consequences: consequence(),
          extras: map(),
          notes: String.t()
        }

  defstruct [
    :name,
    :description,
    :high_concept,
    :trouble,
    aspects: [],
    skills: %{},
    stunts: [],
    refresh: 3,
    fate_points: 3,
    stress_tracks: %{physical: 2, mental: 2},
    consequences: %{mild: nil, moderate: nil, severe: nil},
    extras: %{},
    notes: ""
  ]

  @doc """
  Creates a new character with default values.

  ## Examples

      iex> AriaFate.Character.new()
      %AriaFate.Character{
        name: nil,
        high_concept: nil,
        trouble: nil,
        aspects: [],
        skills: %{},
        stunts: [],
        refresh: 3,
        fate_points: 3,
        stress_tracks: %{physical: 2, mental: 2},
        consequences: %{mild: nil, moderate: nil, severe: nil}
      }
  """
  def new(attrs \\ %{}) do
    struct(__MODULE__, attrs)
  end

  @doc """
  Validates that a character follows Fate Core rules.

  ## Examples

      iex> character = %AriaFate.Character{name: "Test", high_concept: "Hero", trouble: "Reckless"}
      iex> AriaFate.Character.validate(character)
      {:ok, %{valid: true, warnings: []}}
  """
  def validate(%__MODULE__{} = character) do
    errors = []
    warnings = []

    # Check required fields
    errors =
      if is_nil(character.high_concept) or character.high_concept == "",
        do: ["High concept is required" | errors],
        else: errors

    errors =
      if is_nil(character.trouble) or character.trouble == "",
        do: ["Trouble aspect is required" | errors],
        else: errors

    # Validate skill pyramid
    {errors, warnings} = validate_skill_pyramid(character.skills, errors, warnings)

    # Validate refresh
    errors =
      if character.refresh < 1,
        do: ["Refresh must be at least 1" | errors],
        else: errors

    # Validate stunts vs refresh
    stunt_count = length(character.stunts)
    base_stunts = 3
    refresh_cost = max(0, stunt_count - base_stunts)

    errors =
      if character.refresh + refresh_cost < 1,
        do: ["Not enough refresh for stunts (need #{refresh_cost + 1}, have #{character.refresh})" | errors],
        else: errors

    case errors do
      [] -> {:ok, %{valid: true, warnings: warnings}}
      _ -> {:error, %{valid: false, errors: errors, warnings: warnings}}
    end
  end

  @doc """
  Calculates stress track boxes based on relevant skills.

  Physical stress is based on Physique skill.
  Mental stress is based on Will skill.
  """
  def calculate_stress_tracks(%__MODULE__{skills: skills}) do
    physique = Map.get(skills, :physique, 0)
    will = Map.get(skills, :will, 0)

    physical_boxes = 2 + stress_bonus(physique)
    mental_boxes = 2 + stress_bonus(will)

    %{physical: physical_boxes, mental: mental_boxes}
  end

  @doc """
  Returns all aspects for the character (high concept, trouble, and additional aspects).
  """
  def all_aspects(%__MODULE__{high_concept: high_concept, trouble: trouble, aspects: aspects}) do
    [high_concept, trouble | aspects]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Calculates the total skill points spent on the character.
  """
  def skill_points_spent(%__MODULE__{skills: skills}) do
    skills
    |> Map.values()
    |> Enum.sum()
  end

  # Private helper functions

  defp validate_skill_pyramid(skills, errors, warnings) do
    skill_counts = count_skills_by_rating(skills)
    {errors, warnings} = check_pyramid_structure(skill_counts, errors, warnings)
    {errors, warnings}
  end

  defp count_skills_by_rating(skills) do
    skills
    |> Map.values()
    |> Enum.reduce(%{}, fn rating, acc ->
      Map.update(acc, rating, 1, &(&1 + 1))
    end)
  end

  defp check_pyramid_structure(skill_counts, errors, warnings) do
    max_rating = skill_counts |> Map.keys() |> Enum.max(fn -> 0 end)

    # Check pyramid rule: each level should have at least as many skills as the level above
    {errors, warnings} =
      Range.new(1, max_rating, 1)
      |> Enum.reduce({errors, warnings}, fn rating, {acc_errors, acc_warnings} ->
        current_count = Map.get(skill_counts, rating, 0)
        above_count = Map.get(skill_counts, rating + 1, 0)

        if current_count < above_count do
          error_msg = "Skill pyramid invalid: #{current_count} skills at +#{rating}, but #{above_count} at +#{rating + 1}"
          {[error_msg | acc_errors], acc_warnings}
        else
          {acc_errors, acc_warnings}
        end
      end)

    {errors, warnings}
  end

  defp stress_bonus(skill_rating) when skill_rating >= 5, do: 2
  defp stress_bonus(skill_rating) when skill_rating >= 3, do: 1
  defp stress_bonus(_), do: 0
end
