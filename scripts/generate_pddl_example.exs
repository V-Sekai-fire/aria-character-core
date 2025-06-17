# This script demonstrates how to create a simple PDDL domain
# using the new AriaEngine.Pddl structs and print it using AriaEngine.PddlPrinter.

# Ensure the application is started to load all modules
:ok = Application.ensure_all_started(:aria_engine)

alias AriaEngine.Pddl.Domain
alias AriaEngine.Pddl.Domain.{Action, Type, Task, Method, Parameter}
alias AriaEngine.PddlPrinter

# 1. Create a simple PDDL Domain instance
# Define types
object_type = Type.new(:object)
room_type = Type.new(:room, :object)
robot_type = Type.new(:robot, :object)

# Define parameters for actions/tasks
robot_param = Parameter.new(:r, :robot)
from_param = Parameter.new(:from, :room)
to_param = Parameter.new(:to, :room)

# Define a simple action: move
move_action = Action.new(
  :move,
  [robot_param, from_param, to_param],
  # Precondition: (at ?r ?from) and (connected ?from ?to)
  {:and, [
    {:at, [:r, :from]},
    {:connected, [:from, :to]}
  ]},
  # Effect: (not (at ?r ?from)) and (at ?r ?to)
  {:and, [
    {:not, {:at, [:r, :from]}},
    {:at, [:r, :to]}
  ]}
)

# Define a simple task: travel
travel_task = Task.new(
  :travel,
  [robot_param, from_param, to_param]
)

# Define a simple method for travel: direct-move
direct_move_method = Method.new(
  :direct_move,
  travel_task, # Task this method refines
  [robot_param, from_param, to_param], # Parameters for the method
  # Constraints (empty for simplicity)
  [],
  # Ordering (empty for simplicity)
  [],
  # Subtasks: (move ?r ?from ?to)
  [
    Task.new(:move, [robot_param, from_param, to_param])
  ]
)

# Create the domain struct
example_domain = Domain.new(
  :simple_domain,
  requirements: [:strips, :typing],
  types: [object_type, room_type, robot_type],
  predicates: [
    {:at, [:r, :l]},
    {:connected, [:l1, :l2]}
  ],
  functions: [],
  actions: [move_action],
  tasks: [travel_task],
  methods: [direct_move_method]
)

# 2. Use AriaEngine.PddlPrinter.format/2 to convert this instance to a PDDL string.
pddl_string = AriaEngine.PddlPrinter.format(:domain, example_domain)

# 3. Display the generated PDDL string.
IO.puts("Generated PDDL Domain:")
IO.puts(pddl_string)

# You can also write it to a file:
# File.write!("simple_domain.pddl", pddl_string)
