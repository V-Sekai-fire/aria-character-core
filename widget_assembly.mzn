% Widget Assembly Scheduling Problem - MiniZinc Model
% 2 activities: prepare_materials (30min), assemble_widget (45min)
% 1 resource: workstation (capacity 1)
% Dependency: assemble_widget depends on prepare_materials

% Parameters
int: n_activities = 2;
int: n_resources = 1;
set of int: ACTIVITIES = 1..n_activities;
set of int: RESOURCES = 1..n_resources;

% Activity durations (in minutes)
array[ACTIVITIES] of int: duration = [30, 45];

% Activity names for output
array[ACTIVITIES] of string: activity_names = ["prepare_materials", "assemble_widget"];

% Dependencies: activity 2 depends on activity 1
array[ACTIVITIES] of set of int: dependencies = [{}, {1}];

% Resource requirements: both activities need workstation
array[ACTIVITIES, RESOURCES] of 0..1: resource_req = 
  [| 1  % prepare_materials needs workstation
   | 1  % assemble_widget needs workstation
   |];

% Resource capacity
array[RESOURCES] of int: capacity = [1];

% Decision variables
array[ACTIVITIES] of var 0..200: start_time;
var 0..200: makespan;

% Constraints

% 1. Dependency constraints
constraint forall(i in ACTIVITIES, j in dependencies[i])(
  start_time[i] >= start_time[j] + duration[j]
);

% 2. Resource constraints (no overlap for activities using same resource)
constraint forall(i, j in ACTIVITIES where i < j)(
  if sum(r in RESOURCES)(resource_req[i,r] * resource_req[j,r]) > 0 then
    start_time[i] + duration[i] <= start_time[j] \/
    start_time[j] + duration[j] <= start_time[i]
  else true endif
);

% 3. Makespan calculation
constraint makespan = max(i in ACTIVITIES)(start_time[i] + duration[i]);

% Objective: minimize makespan
solve minimize makespan;

% Output
output [
  "=== WIDGET ASSEMBLY SOLUTION ===\n",
  "Activity Schedule:\n"
] ++
[
  "  " ++ activity_names[i] ++ ": start=" ++ show(start_time[i]) ++ 
  ", end=" ++ show(start_time[i] + duration[i]) ++ 
  ", duration=" ++ show(duration[i]) ++ "\n"
  | i in ACTIVITIES
] ++
[
  "\nSolution Summary:\n",
  "  Start times: [" ++ join(", ", [show(start_time[i]) | i in ACTIVITIES]) ++ "]\n",
  "  End times: [" ++ join(", ", [show(start_time[i] + duration[i]) | i in ACTIVITIES]) ++ "]\n",
  "  Total makespan: " ++ show(makespan) ++ " minutes\n"
];
