# Aria Engine Service

## Overview

The Engine Service executes the ported Elixir planning algorithm from the godot-goal-task-planner C++ module, handling character AI decision-making, goal planning, and task execution for generated characters.

## Purpose

To serve as the 'Strategic Mind,' implementing the core planning logic that drives character behavior and decision-making in the RPG world.

## Key Responsibilities

- Execute the ported planning algorithm for character AI behavior and decision-making
- Process character goals and generate task sequences for achieving objectives
- Handle real-time character state evaluation and plan adjustment
- Interface with Architext dataset puzzles to validate planning solutions
- Coordinate with character generation service for behavior consistency

## Core Technologies

- **Ported Planner Algorithm**: C++ planning logic rewritten in Elixir
- **Nx**: Numerical computations in planning algorithms
- **LibGraph**: Graph-based planning and decision trees
- **Architext Dataset Integration**: For puzzle-based planning validation

## Service Type

Stateless

## Key Interactions

- **Shape Service**: For character behavior consistency validation
- **System Data Persistence Service**: For storing character plans, goals, and decision trees
- **Architext Dataset**: For validating planning solutions against known puzzle scenarios
- **Workflow Service**: For integrating character planning into larger game narratives
- **Coordinate Service**: For real-time character behavior execution and monitoring