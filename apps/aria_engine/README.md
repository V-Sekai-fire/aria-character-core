# Aria Engine Service

## Overview

The Engine Service executes classical AI planning using GTPyhop (hierarchical task planner) ported to Elixir, handling character AI decision-making, goal planning, and task execution for generated characters.

## Purpose

To serve as the 'Strategic Mind,' implementing the GTPyhop planning algorithm that drives character behavior and decision-making in the RPG world through hierarchical task decomposition.

## Key Responsibilities

- Execute GTPyhop planning algorithm for character AI behavior and decision-making
- Process character goals and generate task sequences through hierarchical decomposition
- Handle real-time character state evaluation and plan adjustment using predicate-based state representation
- Interface with Architext dataset puzzles to validate planning solutions
- Coordinate with character generation service for behavior consistency
- Manage planning domains with actions, tasks, and goal achievement methods

## Core Technologies

- **GTPyhop Algorithm**: Hierarchical task planner ported from C++ to Elixir
- **Predicate-Based State**: RDF-like triple representation (predicate-subject-object)
- **Hierarchical Planning**: Task decomposition with methods and actions
- **LibGraph**: Graph-based planning and decision trees (future integration)
- **Architext Dataset Integration**: For puzzle-based planning validation

## GTPyhop Features

- **State Management**: Predicate-subject-object triples for world state representation
- **Domain Definition**: Actions, task methods, unigoal methods, and multigoal methods
- **Hierarchical Decomposition**: Tasks break down into subtasks, goals, or actions
- **Goal Achievement**: Multiple methods for achieving single and multiple goals
- **Plan Validation**: Step-by-step execution validation

## Service Type

Stateless

## Key Interactions

- **Shape Service**: For character behavior consistency validation
- **System Data Persistence Service**: For storing character plans, goals, and decision trees
- **Architext Dataset**: For validating planning solutions against known puzzle scenarios
- **Workflow Service**: For integrating character planning into larger game narratives
- **Coordinate Service**: For real-time character behavior execution and monitoring