# Aria Workflow Service

## Overview

The Workflow Service governs the lifecycle of Standard Operating Procedures (SOPs), including their AI-assisted creation, definition, persistent storage, and orchestrated execution across the system.

## Purpose

To serve as the 'Master Planner,' creating clear, step-by-step plans for complex goals, believing that good planning and inspired design (with AI assistance) lead to harmony and success.

## Key Responsibilities

- Provide tools and interfaces for designing and defining SOPs
- Manage the AI-assisted drafting of SOP steps or logic by preparing context and prompts for the Character AI Service
- Validate the logical consistency and feasibility of SOPs
- Store and version SOP definitions and related configurations securely
- Orchestrate the step-by-step execution of active SOPs using planning tools
- Manage the state, monitoring, and logging of SOP executions

## Core Technologies

- **LibGraph**: For SOP execution planning and control flow
- **GenStateMachine**: For workflow state management
- **Application logic**: SOP definition, AI interaction, and lifecycle management

## Service Type

Stateful (SOP definitions and execution state are persisted via the System Data Persistence Service)

## Key Interactions

- **Character AI Service**: For AI-assisted SOP drafting and decision support
- **System Data Persistence Service**: For persistent SOP storage and state management
- **Coordinate Service**: To initiate, manage, and monitor workflow executions
- **Engine Service**: For planning and decision-making within SOPs
- **Interpret Service**: For analysis and understanding of workflow results
- **Various Services**: Invoked by SOPs to perform specific tasks