# Aria Shape Service

## Overview

The Shape Service provides centralized character generation, training data synthesis, and multimodal content creation using advanced reasoning models. This service combines the Qwen3 ONNX model with GRPO training to generate coherent RPG characters, their backstories, abilities, and associated assets.

## System Role

**Boot Order:** Intelligence Layer (Boot Third)
**Dependencies:** `aria_security`, `aria_data`, `aria_storage`, `aria_queue`
**External Systems:** Python, PyTorch, Qwen3/GRPO models

## Purpose

To act as the 'Character Shaper & Master Storyteller,' molding digital beings into existence through advanced reasoning and creative generation, iteratively refining them through machine learning feedback loops.

## Key Responsibilities

- Execute Qwen3 ONNX model inference for character generation and narrative creation
- Implement Group Relative Policy Optimization (GRPO) for continuous character generation improvement
- Generate character attributes, backstories, dialogue, and behavioral patterns
- Create training data synthesis from Architext dataset puzzles for character decision-making
- Perform multimodal content generation (text, structured data, GLTF model parameters)
- Support iterative character refinement through reinforcement learning feedback loops

## Core Technologies

- **Qwen3 ONNX Model**: Advanced multimodal reasoning LLM for character generation
- **Ortex**: ONNX model execution in Elixir
- **Nx**: Foundational library for numerical computing and tensor operations
- **GRPO Implementation**: Group Relative Policy Optimization for character generation training
- **GPU-accelerated inference**: Serving frameworks for model execution

## Technology Choices

- **Python Integration**: While the core system is Elixir-based, this service plans to incorporate Python for specialized AI/ML tasks, leveraging its extensive libraries and ecosystem. This allows for the use of powerful tools like PyTorch and integration with ML frameworks like FLAME.
  - PyTorch: <https://pytorch.org/get-started/locally/>
  - FLAME: <https://github.com/phoenixframework/flame>

## Service Type

Stateless (inference process itself; models are loaded state)

## Key Interactions

- **Workflow Service**: For workflow orchestration and SOP execution involving character shaping
- **Interpret Service**: For analyzing character behavior patterns and narrative coherence
- **Bulk Data Persistence Service**: For storing and retrieving ONNX models, GLTF assets, and training datasets
- **System Data Persistence Service**: For storing character metadata, training metrics, and generation history
- **Interface Service**: For processing character generation requests and returning completed characters
- **Queue Service**: For managing long-running character generation and training jobs via Oban workers