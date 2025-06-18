# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domains.SnakeDomain do
  alias AriaEngine.Domain
  alias AriaEngine.State

  @doc """
  Defines the Snake planning domain.
  """
  def domain do
    Domain.new("snake")
    |> add_actions()
    |> add_task_methods()
    |> add_unigoal_methods()
  end

  defp add_actions(domain) do
    domain
    |> Domain.add_action(:strike, &strike/2)
    |> Domain.add_action(:move_short, &move_short/2)
    |> Domain.add_action(:move_long, &move_long/2)
  end

  defp add_task_methods(domain) do
    domain
    |> Domain.add_task_methods("hunt", [
      {"hunt_all", &hunt_all/2},
      {"hunt_done", &hunt_done/2}
    ])
    |> Domain.add_task_methods("move", [
      {"move_base", &move_base/2},
      {"move_long_snake", &move_long_snake/2},
      {"move_short_snake", &move_short_snake/2}
    ])
  end

  defp add_unigoal_methods(domain) do
    domain
    # No explicit unigoal methods in the PDDL, but the planner might generate them.
    # For now, leave empty or add if needed later.
  end

  # --- Actions ---

  @doc """
  Action: strike
  Parameters: (?snake - snake ?headpos ?foodpos - location)
  """
  def strike(state, [snake, headpos, foodpos]) do
    # Preconditions:
    # (head ?snake ?headpos)
    # (mouse-at ?foodpos)
    # (adjacent ?foodpos ?headpos)
    # (not (= ?headpos ?foodpos))

    cond do
      State.get_fact(state, "head", Atom.to_string(snake)) != Atom.to_string(headpos) ->
        false
      State.get_fact(state, "mouse-at", Atom.to_string(foodpos)) != true ->
        false
      State.get_fact(state, "adjacent", "#{Atom.to_string(foodpos)}-#{Atom.to_string(headpos)}") != true ->
        false
      headpos == foodpos ->
        false
      true ->
        # Effects:
        # (not (mouse-at ?foodpos))
        # (not (head ?snake ?headpos))
        # (connected ?snake ?foodpos ?headpos)
        # (head ?snake ?foodpos)

        state
        |> State.remove_fact("mouse-at", Atom.to_string(foodpos))
        |> State.remove_fact("head", Atom.to_string(snake))
        |> State.set_fact("connected", "#{Atom.to_string(foodpos)}-#{Atom.to_string(headpos)}", true)
        |> State.set_fact("head", Atom.to_string(snake), Atom.to_string(foodpos))
    end
  end

  @doc """
  Action: move-short
  Parameters: (?snake - snake ?nextpos ?snakepos - location)
  """
  def move_short(state, [snake, nextpos, snakepos]) do
    # Preconditions:
    # (head ?snake ?snakepos)
    # (tail ?snake ?snakepos)
    # (adjacent ?nextpos ?snakepos)
    # (not (occupied ?nextpos))

    cond do
      State.get_fact(state, "head", Atom.to_string(snake)) != Atom.to_string(snakepos) ->
        false
      State.get_fact(state, "tail", Atom.to_string(snake)) != Atom.to_string(snakepos) ->
        false
      State.get_fact(state, "adjacent", "#{Atom.to_string(nextpos)}-#{Atom.to_string(snakepos)}") != true ->
        false
      State.get_fact(state, "occupied", Atom.to_string(nextpos)) == true ->
        false
      true ->
        # Effects:
        # (not (head ?snake ?snakepos))
        # (not (tail ?snake ?snakepos))
        # (occupied ?nextpos)
        # (head ?snake ?nextpos)
        # (tail ?snake ?nextpos)
        # (not (occupied ?snakepos))

        state
        |> State.remove_fact("head", Atom.to_string(snake))
        |> State.remove_fact("tail", Atom.to_string(snake))
        |> State.set_fact("occupied", Atom.to_string(nextpos), true)
        |> State.set_fact("head", Atom.to_string(snake), Atom.to_string(nextpos))
        |> State.set_fact("tail", Atom.to_string(snake), Atom.to_string(nextpos))
        |> State.remove_fact("occupied", Atom.to_string(snakepos))
    end
  end

  @doc """
  Action: move-long
  Parameters: (?snake - snake ?nextpos ?headpos ?bodypos ?tailpos - location)
  """
  def move_long(state, [snake, nextpos, headpos, bodypos, tailpos]) do
    # Preconditions:
    # (head ?snake ?headpos)
    # (connected ?snake ?bodypos ?tailpos)
    # (tail ?snake ?tailpos)
    # (adjacent ?nextpos ?headpos)
    # (adjacent ?bodypos ?tailpos)
    # (not (occupied ?nextpos))
    # (not (= ?bodypos ?nextpos))
    # (not (= ?tailpos ?nextpos))
    # (not (= ?headpos ?tailpos))

    cond do
      State.get_fact(state, "head", Atom.to_string(snake)) != Atom.to_string(headpos) ->
        false
      State.get_fact(state, "connected", "#{Atom.to_string(bodypos)}-#{Atom.to_string(tailpos)}") != true ->
        false
      State.get_fact(state, "tail", Atom.to_string(snake)) != Atom.to_string(tailpos) ->
        false
      State.get_fact(state, "adjacent", "#{Atom.to_string(nextpos)}-#{Atom.to_string(headpos)}") != true ->
        false
      State.get_fact(state, "adjacent", "#{Atom.to_string(bodypos)}-#{Atom.to_string(tailpos)}") != true ->
        false
      State.get_fact(state, "occupied", Atom.to_string(nextpos)) == true ->
        false
      bodypos == nextpos ->
        false
      tailpos == nextpos ->
        false
      headpos == tailpos ->
        false
      true ->
        # Effects:
        # (not (head ?snake ?headpos))
        # (head ?snake ?nextpos)
        # (not (tail ?snake ?tailpos))
        # (tail ?snake ?bodypos)
        # (not (connected ?snake ?bodypos ?tailpos))
        # (connected ?snake ?nextpos ?headpos)
        # (occupied ?nextpos)
        # (not (occupied ?tailpos))

        state
        |> State.remove_fact("head", Atom.to_string(snake))
        |> State.set_fact("head", Atom.to_string(snake), Atom.to_string(nextpos))
        |> State.remove_fact("tail", Atom.to_string(snake))
        |> State.set_fact("tail", Atom.to_string(snake), Atom.to_string(bodypos))
        |> State.remove_fact("connected", "#{Atom.to_string(bodypos)}-#{Atom.to_string(tailpos)}")
        |> State.set_fact("connected", "#{Atom.to_string(nextpos)}-#{Atom.to_string(headpos)}", true)
        |> State.set_fact("occupied", Atom.to_string(nextpos), true)
        |> State.remove_fact("occupied", Atom.to_string(tailpos))
    end
  end

  # --- Task Methods ---

  @doc """
  Method: hunt_all
  Parameters: (?snake - snake ?foodpos ?snakepos ?pos1 - location)
  Task: (hunt)
  """
  def hunt_all(state, [snake, foodpos, snakepos, pos1]) do
    # Precondition:
    # (mouse-at ?foodpos)
    # (head ?snake ?snakepos)
    # (adjacent ?foodpos ?pos1)

    cond do
      State.get_fact(state, "mouse-at", Atom.to_string(foodpos)) != true ->
        false
      State.get_fact(state, "head", Atom.to_string(snake)) != Atom.to_string(snakepos) ->
        false
      State.get_fact(state, "adjacent", "#{Atom.to_string(foodpos)}-#{Atom.to_string(pos1)}") != true ->
        false
      true ->
        # Ordered Subtasks:
        # (move ?snake ?snakepos ?pos1)
        # (strike ?snake ?pos1 ?foodpos)
        # (hunt)
        [
          {:move, snake, snakepos, pos1},
          {:strike, snake, pos1, foodpos},
          {:hunt}
        ]
    end
  end

  @doc """
  Method: hunt_done
  Parameters: ()
  Task: (hunt)
  """
  def hunt_done(state, []) do
    # Precondition: (forall (?pos - location) (not (mouse-at ?pos)))
    # This is a universal precondition, which is hard to check directly in this model.
    # For simplicity, we'll assume it's true if no mouse-at facts are present.
    # A more robust check would iterate all possible locations.
    
    # Check if there are any "mouse-at" facts in the state
    if Enum.any?(State.to_triples(state), fn {pred, _sub, _val} -> pred == "mouse-at" end) do
      false # There's still a mouse
    else
      [] # No subtasks, meaning hunt is done
    end
  end

  @doc """
  Method: move-base
  Parameters: (?snake - snake ?snakepos ?goalpos - location)
  Task: (move ?snake ?snakepos ?goalpos)
  """
  def move_base(state, [snake, snakepos, goalpos]) do
    # Precondition: (= ?snakepos ?goalpos)
    cond do
      snakepos != goalpos ->
        false
      true ->
        [] # No subtasks, already at goal
    end
  end

  @doc """
  Method: move-long-snake
  Parameters: (?snake - snake ?snakepos ?goalpos ?pos2 ?bodypos ?tailpos - location)
  Task: (move ?snake ?snakepos ?goalpos)
  """
  def move_long_snake(state, [snake, snakepos, goalpos, pos2, bodypos, tailpos]) do
    # Precondition:
    # (adjacent ?pos2 ?snakepos)
    # (not (occupied ?pos2))
    # (connected ?snake ?bodypos ?tailpos)
    # (tail ?snake ?tailpos)

    cond do
      State.get_fact(state, "adjacent", "#{Atom.to_string(pos2)}-#{Atom.to_string(snakepos)}") != true ->
        false
      State.get_fact(state, "occupied", Atom.to_string(pos2)) == true ->
        false
      State.get_fact(state, "connected", "#{Atom.to_string(bodypos)}-#{Atom.to_string(tailpos)}") != true ->
        false
      State.get_fact(state, "tail", Atom.to_string(snake)) != Atom.to_string(tailpos) ->
        false
      true ->
        # Ordered Subtasks:
        # (move-long ?snake ?pos2 ?snakepos ?bodypos ?tailpos)
        # (move ?snake ?pos2 ?goalpos)
        [
          {:move_long, snake, pos2, snakepos, bodypos, tailpos},
          {:move, snake, pos2, goalpos}
        ]
    end
  end

  @doc """
  Method: move-short-snake
  Parameters: (?snake - snake ?snakepos ?goalpos ?pos2 - location)
  Task: (move ?snake ?snakepos ?goalpos)
  """
  def move_short_snake(state, [snake, snakepos, goalpos, pos2]) do
    # Precondition:
    # (adjacent ?pos2 ?snakepos)
    # (not (occupied ?pos2))
    # (tail ?snake ?snakepos)

    cond do
      State.get_fact(state, "adjacent", "#{Atom.to_string(pos2)}-#{Atom.to_string(snakepos)}") != true ->
        false
      State.get_fact(state, "occupied", Atom.to_string(pos2)) == true ->
        false
      State.get_fact(state, "tail", Atom.to_string(snake)) != Atom.to_string(snakepos) ->
        false
      true ->
        # Ordered Subtasks:
        # (move-short ?snake ?pos2 ?snakepos)
        # (move ?snake ?pos2 ?goalpos)
        [
          {:move_short, snake, pos2, snakepos},
          {:move, snake, pos2, goalpos}
        ]
    end
  end
end
