# R25W14917FB: ART Reinforcement Learning for Qwen3 ARC Prize Optimization

<!-- @adr_serial R25W14917FB -->

**Status:** Paused  
**Date:** 2025-06-25  
**Priority:** MEDIUM  
**Prerequisites:** R25W148122A (LLM Actions Implementation) + Phase 1-2 ARC Prize completion

## Context

Implement sophisticated reinforcement learning for Qwen3 using OpenPipe's ART (Automated Reasoning and Tool-use) framework to create a continuously improving ARC puzzle solver. ART specializes in training models on multi-step reasoning tasks with tool integration, making it ideal for ARC puzzle solving where the model must reason through patterns and use computational search tools effectively.

**Why ART for ARC Prize:**

- **Tool-Aware Training**: Optimizes models that use external tools (search functions, pattern analyzers)
- **Reasoning Chain Optimization**: Specifically designed for multi-step reasoning improvement
- **Production-Ready Framework**: Battle-tested system from OpenPipe with monitoring and deployment
- **Sophisticated Reward Modeling**: Handles complex reward functions for reasoning quality assessment
- **Continuous Learning**: Seamless integration with ongoing data collection and model updates

**Target**: Create self-improving ARC solver that learns from every puzzle attempt to consistently beat 34% human success rate.

## Decision

Implement ART-based reinforcement learning system using OpenPipe's framework, integrated as Phase 3 enhancement (post-sprint continuous improvement) to create domain-specialized Qwen3 models for ARC puzzle solving.

**Architecture Strategy:**

1. **Trajectory Collection** - Capture reasoning chains with tool usage from ARC attempts
2. **ART Dataset Formatting** - Convert trajectories to ART's tool-aware training format
3. **Reward Function Design** - Multi-factor reward system for accuracy, reasoning quality, and efficiency
4. **Training Pipeline** - Automated ART training with model deployment
5. **Continuous Learning Loop** - Every puzzle attempt improves future performance

## Implementation Plan

### Phase 3 Implementation Timeline (Post-Sprint: Week 5+)

**Week 5: ART Infrastructure Setup**

- [ ] **ART Server Deployment**
  - [ ] Set up OpenPipe ART server using Docker Compose
  - [ ] Configure PostgreSQL database for ART training data
  - [ ] Establish API connectivity between Elixir system and ART server
  - [ ] Test basic ART training pipeline with sample data

- [ ] **Elixir ART Integration**
  - [ ] Implement `AriaArc.ARTClient` for ART server communication
  - [ ] Add `AriaArc.ARTTrainer` for training run management
  - [ ] Create `AriaArc.ARTDatasetFormatter` for trajectory conversion
  - [ ] Implement `AriaArc.ModelManager` for model version tracking

**Week 6: Dataset and Reward System**

- [ ] **Trajectory Collection Enhancement**
  - [ ] Enhance existing LLM actions to capture tool usage patterns
  - [ ] Implement comprehensive reasoning chain tracking
  - [ ] Add trajectory quality assessment and filtering
  - [ ] Create trajectory storage and retrieval system

- [ ] **ART Reward Function Design**
  - [ ] Implement multi-factor reward calculation (accuracy + reasoning + efficiency)
  - [ ] Add bonus rewards for novel pattern discovery and efficient solutions
  - [ ] Create penalty system for invalid tool usage and circular reasoning
  - [ ] Test reward function calibration with sample trajectories

**Week 7: Training Pipeline and Model Deployment**

- [ ] **ART Training Pipeline**
  - [ ] Implement automated training run creation and monitoring
  - [ ] Add training progress tracking and logging
  - [ ] Create model evaluation and validation system
  - [ ] Implement automated model deployment upon training completion

- [ ] **Integration Testing**
  - [ ] Test complete trajectory collection → ART training → model deployment cycle
  - [ ] Validate ART-trained model performance on ARC validation set
  - [ ] Measure accuracy improvements over baseline models
  - [ ] Document training effectiveness and model quality metrics

## Technical Architecture

### ART Server Infrastructure

```yaml
# docker-compose.yml for ART deployment
version: '3.8'
services:
  art-server:
    image: openpipe/art:latest
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - ART_DB_URL=postgresql://art:password@postgres:5432/art
      - ART_LOG_LEVEL=info
    volumes:
      - ./art_data:/app/data
      - ./art_models:/app/models
    depends_on:
      - postgres
      
  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=art
      - POSTGRES_USER=art
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
  art_data:
  art_models:
```

### ART Client Integration

```elixir
defmodule AriaArc.ARTClient do
  @art_endpoint "http://localhost:8000"
  
  def create_training_run(dataset, reward_config, training_config \\ %{}) do
    request_body = %{
      "base_model" => "qwen/qwen-2.5-7b-instruct",
      "dataset" => dataset,
      "reward_function" => reward_config,
      "training_config" => Map.merge(default_training_config(), training_config),
      "evaluation_config" => default_evaluation_config()
    }
    
    case HTTPoison.post("#{@art_endpoint}/training/create", 
                       Jason.encode!(request_body),
                       [{"Content-Type", "application/json"}],
                       timeout: 60_000) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"run_id" => run_id}} ->
            {:ok, run_id}
          {:error, reason} ->
            {:error, "Failed to parse ART response: #{reason}"}
        end
      {:ok, %{status_code: status, body: body}} ->
        {:error, "ART training creation failed (#{status}): #{body}"}
      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end
  
  def get_training_status(run_id) do
    case HTTPoison.get("#{@art_endpoint}/training/#{run_id}/status") do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, status_data} ->
            {:ok, status_data}
          {:error, reason} ->
            {:error, "Failed to parse status response: #{reason}"}
        end
      {:ok, %{status_code: 404}} ->
        {:error, "Training run not found"}
      {:error, reason} ->
        {:error, "Failed to get training status: #{inspect(reason)}"}
    end
  end
  
  def complete_with_tools(model_id, conversation, opts \\ []) do
    tools = Keyword.get(opts, :tools, arc_tools())
    
    request_body = %{
      "model" => model_id,
      "messages" => conversation,
      "tools" => tools,
      "tool_choice" => "auto",
      "temperature" => 0.1,
      "max_tokens" => 2048
    }
    
    case HTTPoison.post("#{@art_endpoint}/chat/completions",
                       Jason.encode!(request_body),
                       [{"Content-Type", "application/json"}],
                       timeout: 120_000) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"choices" => [%{"message" => message} | _]}} ->
            {:ok, message}
          {:error, reason} ->
            {:error, "Failed to parse completion response: #{reason}"}
        end
      {:ok, %{status_code: status, body: body}} ->
        {:error, "ART completion failed (#{status}): #{body}"}
      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end
  
  defp default_training_config do
    %{
      "learning_rate" => 1e-5,
      "batch_size" => 8,
      "num_epochs" => 3,
      "warmup_steps" => 100,
      "gradient_accumulation_steps" => 4,
      "max_sequence_length" => 4096
    }
  end
  
  defp default_evaluation_config do
    %{
      "eval_steps" => 50,
      "eval_dataset_size" => 100,
      "save_best_model" => true,
      "early_stopping_patience" => 3
    }
  end
  
  defp arc_tools do
    [
      %{
        "type" => "function",
        "function" => %{
          "name" => "analyze_pattern",
          "description" => "Analyze visual patterns in an ARC puzzle grid to identify transformation rules",
          "parameters" => %{
            "type" => "object",
            "properties" => %{
              "grid" => %{
                "type" => "array",
                "description" => "2D array representing the puzzle grid",
                "items" => %{"type" => "array", "items" => %{"type" => "integer"}}
              },
              "focus_area" => %{
                "type" => "string",
                "description" => "Specific pattern type to focus analysis on",
                "enum" => ["symmetry", "color_mapping", "shape_operations", "spatial_relationships", "object_detection", "repetition"]
              }
            },
            "required" => ["grid", "focus_area"]
          }
        }
      },
      %{
        "type" => "function",
        "function" => %{
          "name" => "search_transformations",
          "description" => "Search for possible transformations using computational methods",
          "parameters" => %{
            "type" => "object",
            "properties" => %{
              "hypotheses" => %{
                "type" => "array",
                "description" => "List of transformation hypotheses to test",
                "items" => %{"type" => "string"}
              },
              "search_budget" => %{
                "type" => "integer",
                "description" => "Number of transformations to evaluate",
                "minimum" => 10,
                "maximum" => 1000
              },
              "focus_area" => %{
                "type" => "string",
                "description" => "Area to focus search efforts",
                "enum" => ["initial_exploration", "hypothesis_validation", "working_element_refinement"]
              }
            },
            "required" => ["hypotheses", "search_budget"]
          }
        }
      },
      %{
        "type" => "function",
        "function" => %{
          "name" => "validate_solution",
          "description" => "Validate a proposed solution approach and assess confidence",
          "parameters" => %{
            "type" => "object",
            "properties" => %{
              "approach" => %{
                "type" => "string",
                "description" => "Description of the transformation approach to validate"
              },
              "test_grid" => %{
                "type" => "array",
                "description" => "Test grid to apply the transformation to",
                "items" => %{"type" => "array", "items" => %{"type" => "integer"}}
              },
              "confidence_threshold" => %{
                "type" => "number",
                "description" => "Minimum confidence level required for acceptance",
                "minimum" => 0.0,
                "maximum" => 1.0
              }
            },
            "required" => ["approach", "test_grid"]
          }
        }
      }
    ]
  end
end
```

### ART Dataset Formatting

```elixir
defmodule AriaArc.ARTDatasetFormatter do
  def format_trajectory_for_art(trajectory) do
    %{
      "conversation" => build_conversation_from_trajectory(trajectory),
      "tools" => AriaArc.ARTClient.arc_tools(),
      "reward" => calculate_trajectory_reward(trajectory),
      "metadata" => %{
        "puzzle_id" => trajectory.puzzle_id,
        "accuracy" => trajectory.final_accuracy,
        "reasoning_depth" => length(trajectory.reasoning_steps),
        "tool_usage_count" => count_tool_usage(trajectory.reasoning_steps),
        "timestamp" => trajectory.timestamp
      }
    }
  end
  
  defp build_conversation_from_trajectory(trajectory) do
    [
      %{
        "role" => "system",
        "content" => "You are an expert ARC puzzle solver with access to analysis and search tools. Use step-by-step reasoning and appropriate tool calls to solve puzzles efficiently."
      },
      %{
        "role" => "user",
        "content" => format_puzzle_prompt(trajectory)
      },
      %{
        "role" => "assistant",
        "content" => format_reasoning_with_tool_calls(trajectory.reasoning_steps)
      }
    ]
  end
  
  defp format_puzzle_prompt(trajectory) do
    """
    Solve this ARC (Abstract Reasoning Challenge) puzzle:
    
    Input Grid:
    #{format_grid_for_display(trajectory.input_grid)}
    
    Expected Output Pattern (from training examples):
    #{format_grid_for_display(trajectory.expected_output)}
    
    Your task is to:
    1. Analyze the pattern in the input grid
    2. Generate hypotheses about the transformation rule
    3. Use search tools to validate your hypotheses
    4. Provide a confident solution approach
    
    Use the available tools systematically to solve this puzzle.
    """
  end
  
  defp format_reasoning_with_tool_calls(reasoning_steps) do
    reasoning_steps
    |> Enum.with_index(1)
    |> Enum.map(fn {step, index} ->
      format_reasoning_step_with_tools(step, index)
    end)
    |> Enum.join("\n\n")
  end
  
  defp format_reasoning_step_with_tools(step, step_number) do
    case step.action do
      :analyze_pattern ->
        """
        Step #{step_number}: Pattern Analysis
        
        I need to analyze this grid to understand the underlying transformation rule. Let me focus on #{step.input.focus_area || "general patterns"}.
        
        <tool_call>
        {"name": "analyze_pattern", "parameters": {"grid": #{Jason.encode!(step.input.grid)}, "focus_area": "#{step.input.focus_area || "symmetry"}"}}
        </tool_call>
        
        Analysis Result: #{format_analysis_result(step.output)}
        
        This suggests the transformation involves #{extract_key_insight(step.output)}.
        """
        
      :generate_transformation_hypothesis ->
        """
        Step #{step_number}: Hypothesis Generation
        
        Based on the pattern analysis, I can generate several transformation hypotheses:
        #{format_hypotheses(step.output)}
        
        These hypotheses need to be tested through computational search.
        """
        
      :llm_guided_search_with_constraints ->
        """
        Step #{step_number}: Computational Search
        
        Now I'll search for transformations that match my hypotheses, avoiding known impossible approaches.
        
        <tool_call>
        {"name": "search_transformations", "parameters": {"hypotheses": #{Jason.encode!(extract_hypotheses(step.input))}, "search_budget": #{step.input.search_budget}, "focus_area": "#{step.input.focus_area}"}}
        </tool_call>
        
        Search Results: #{format_search_results(step.output)}
        
        The search found #{count_successful_transformations(step.output)} promising approaches.
        """
        
      :validate_solution_approach ->
        """
        Step #{step_number}: Solution Validation
        
        Let me validate the most promising solution approach to ensure confidence.
        
        <tool_call>
        {"name": "validate_solution", "parameters": {"approach": "#{step.input.approach}", "test_grid": #{Jason.encode!(step.input.test_grid)}, "confidence_threshold": 0.8}}
        </tool_call>
        
        Validation Result: #{format_validation_result(step.output)}
        
        #{generate_confidence_statement(step.output)}
        """
        
      _ ->
        """
        Step #{step_number}: #{humanize_action(step.action)}
        
        #{format_generic_step(step)}
        """
    end
  end
  
  defp calculate_trajectory_reward(trajectory) do
    AriaArc.ARTRewardFunction.calculate_comprehensive_reward(trajectory)
  end
  
  defp count_tool_usage(reasoning_steps) do
    reasoning_steps
    |> Enum.count(fn step -> 
      step.action in [:analyze_pattern, :llm_guided_search_with_constraints, :validate_solution_approach]
    end)
  end
end
```

### ART Reward Function

```elixir
defmodule AriaArc.ARTRewardFunction do
  def create_arc_reward_config do
    %{
      "reward_type" => "custom",
      "reward_function" => %{
        "primary_factors" => %{
          "accuracy_weight" => 0.6,           # Primary: solution accuracy
          "reasoning_quality_weight" => 0.25, # Secondary: reasoning chain quality
          "efficiency_weight" => 0.15         # Tertiary: computational efficiency
        },
        "bonus_rewards" => %{
          "perfect_solution" => 1.0,          # 100% accuracy bonus
          "novel_pattern_discovery" => 0.5,   # Discovering new pattern types
          "efficient_search" => 0.3,          # Finding solution with minimal search
          "coherent_reasoning" => 0.4,        # Logical, step-by-step reasoning
          "appropriate_tool_usage" => 0.2     # Using tools effectively
        },
        "penalty_factors" => %{
          "invalid_tool_calls" => -0.3,       # Incorrect tool usage
          "circular_reasoning" => -0.4,       # Repetitive or contradictory reasoning
          "failed_validation" => -0.2,        # Solutions that fail validation
          "excessive_search" => -0.1,         # Inefficient search patterns
          "incomplete_reasoning" => -0.3      # Skipping important reasoning steps
        },
        "quality_thresholds" => %{
          "minimum_accuracy" => 0.1,          # Below this gets heavy penalty
          "good_accuracy" => 0.5,             # Above this gets bonus
          "excellent_accuracy" => 0.8,        # Above this gets large bonus
          "reasoning_coherence_threshold" => 0.7,
          "tool_usage_efficiency_threshold" => 0.6
        }
      },
      "evaluation_metrics" => [
        "solution_accuracy",
        "reasoning_coherence_score",
        "tool_usage_efficiency",
        "pattern_recognition_quality",
        "search_efficiency",
        "validation_success_rate"
      ]
    }
  end
  
  def calculate_comprehensive_reward(trajectory) do
    # Base accuracy reward (0.0 to 1.0)
    accuracy_reward = trajectory.final_accuracy / 100.0
    
    # Reasoning quality assessment (0.0 to 1.0)
    reasoning_quality = assess_reasoning_quality(trajectory.reasoning_steps)
    
    # Efficiency assessment (0.0 to 1.0)
    efficiency_score = assess_computational_efficiency(trajectory)
    
    # Calculate bonus rewards
    bonus_total = calculate_bonus_rewards(trajectory, accuracy_reward, reasoning_quality)
    
    # Calculate penalties
    penalty_total = calculate_penalties(trajectory)
    
    # Weighted combination
    base_reward = (accuracy_reward * 0.6) + 
                  (reasoning_quality * 0.25) + 
                  (efficiency_score * 0.15)
    
    total_reward = base_reward + bonus_total - penalty_total
    
    # Clamp to valid range
    max(0.0, min(2.0, total_reward))  # Allow rewards up to 2.0 for exceptional performance
  end
  
  defp assess_reasoning_quality(reasoning_steps) do
    if length(reasoning_steps) == 0, do: 0.0
    
    # Assess logical flow, tool usage appropriateness, and coherence
    logical_flow_score = assess_logical_flow(reasoning_steps)
    tool_usage_score = assess_tool_usage_appropriateness(reasoning_steps)
    coherence_score = assess_reasoning_coherence(reasoning_steps)
    
    (logical_flow_score + tool_usage_score + coherence_score) / 3.0
  end
  
  defp assess_computational_efficiency(trajectory) do
    total_search_budget = calculate_total_search_budget(trajectory.reasoning_steps)
    reasoning_steps_count = length(trajectory.reasoning_steps)
    
    # Efficiency based on achieving high accuracy with minimal resources
    case trajectory.final_accuracy do
      acc when acc >= 90 and total_search_budget <= 500 -> 1.0
      acc when acc >= 80 and total_search_budget <= 800 -> 0.8
      acc when acc >= 60 and total_search_budget <= 1200 -> 0.6
      acc when acc >= 40 -> 0.4
      _ -> 0.2
    end
  end
  
  defp calculate_bonus_rewards(trajectory, accuracy_reward, reasoning_quality) do
    bonus = 0.0
    
    # Perfect solution bonus
    bonus = if trajectory.final_accuracy >= 95, do: bonus + 1.0, else: bonus
    
    # Novel pattern discovery bonus (check if new patterns were identified)
    bonus = if discovered_novel_patterns?(trajectory), do: bonus + 0.5, else: bonus
    
    # Efficient search bonus
    bonus = if efficient_search?(trajectory), do: bonus + 0.3, else: bonus
    
    # Coherent reasoning bonus
    bonus = if reasoning_quality >= 0.8, do: bonus + 0.4, else: bonus
    
    # Appropriate tool usage bonus
    bonus = if appropriate_tool_usage?(trajectory), do: bonus + 0.2, else: bonus
    
    bonus
  end
  
  defp calculate_penalties(trajectory) do
    penalty = 0.0
    
    # Invalid tool calls penalty
    penalty = penalty + (count_invalid_tool_calls(trajectory) * 0.3)
    
    # Circular reasoning penalty
    penalty = if circular_reasoning?(trajectory), do: penalty + 0.4, else: penalty
    
    # Failed validation penalty
    penalty = penalty + (count_failed_validations(trajectory) * 0.2)
    
    # Excessive search penalty
    penalty = if excessive_search?(trajectory), do: penalty + 0.1, else: penalty
    
    # Incomplete reasoning penalty
    penalty = if incomplete_reasoning?(trajectory), do: penalty + 0.3, else: penalty
    
    penalty
  end
end
```

### ART Training Pipeline

```elixir
defmodule AriaArc.ARTTrainingPipeline do
  use GenServer
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
  
  def init(state) do
    # Check for training opportunities every 2 hours
    :timer.send_interval(7_200_000, :check_training_trigger)
    {:ok, state}
  end
  
  def trigger_training_if_ready do
    GenServer.cast(__MODULE__, :check_training_trigger)
  end
  
  def handle_cast(:check_training_trigger, state) do
    case should_trigger_training?() do
      {:yes, trajectory_count} ->
        Logger.info("Triggering ART training with #{trajectory_count} trajectories")
        spawn(fn -> execute_art_training() end)
      {:no, reason} ->
        Logger.debug("ART training not triggered: #{reason}")
    end
    
    {:noreply, state}
  end
  
  def handle_info(:check_training_trigger, state) do
    handle_cast(:check_training_trigger, state)
  end
  
  defp should_trigger_training? do
    successful_count = AriaArc.TrajectoryStore.count_successful_trajectories()
    failed_count = AriaArc.TrajectoryStore.count_failed_trajectories()
    total_count = successful_count + failed_count
    
    cond do
      total_count >= 100 and successful_count >= 20 ->
        {:yes, total_count}
      total_count < 50 ->
        {:no, "Need at least 50 trajectories (have #{total_count})"}
      successful_count < 10 ->
        {:no, "Need at least 10 successful trajectories (have #{successful_count})"}
      true ->
        {:no, "Training conditions not met"}
    end
  end
  
  defp execute_art_training do
    try do
      # Collect and format trajectories
      trajectories = AriaArc.TrajectoryStore.get_all_trajectories()
      art_dataset = Enum.map(trajectories, &AriaArc.ARTDatasetFormatter.format_trajectory_for_art/1)
      
      # Create reward configuration
      reward_config = AriaArc.ARTRewardFunction.create_arc_reward_config()
      
      # Start ART training run
      case AriaArc.ARTClient.create_training_run(art_dataset, reward_config) do
        {:ok, run_id} ->
          Logger.info("ART training started with run ID: #{run_id}")
          monitor_training_progress(run_id)
        {:error, reason} ->
          Logger.error("Failed to start ART training: #{reason}")
      end
    rescue
      error ->
        Logger.error("ART training execution failed: #{inspect(error)}")
    end
  end
  
  defp monitor_training_progress(run_id) do
    case AriaArc.ARTClient.get_training_status(run_id) do
      {:ok, %{"status" => "completed", "model" => model_info}} ->
        Logger.info("ART training completed successfully")
        deploy_trained_model(model_info)
        
      {:ok, %{"status" => "running", "progress" => progress}} ->
        Logger.info("ART training progress: #{progress}%")
        :timer.sleep(60_000)  # Check again in 1 minute
        monitor_training_progress(run_id)
        
      {:ok, %{"status" => "failed", "error" => error}} ->
        Logger.error("ART training failed: #{error}")
        
      {:error, reason} ->
        Logger.error("Failed to get training status: #{reason}")
        :timer.sleep(60_000)
        monitor_training_progress(run_id)
    end
  end
  
  defp deploy_trained_model(model_info) do
    case AriaArc.ModelManager.deploy_art_model(model_info) do
      {:ok, deployment_info} ->
        Logger.info("ART-trained model deployed successfully: #{deployment_info.model_id}")
        
        # Test the new model
        validation_results = test_model_performance(deployment_info.model_id)
        Logger.info("New model validation accuracy: #{validation_results.accuracy}%")
        
        # Clear old trajectories after successful training
        AriaArc.TrajectoryStore.archive_trajectories()
        
      {:error, reason} ->
        Logger.error("Failed to deploy ART-trained model: #{reason}")
    end
  end
  
  defp test_model_performance(model_id) do
    # Test on a small validation set of ARC puzzles
    validation_puzzles = AriaArc.ValidationSet.get_sample_puzzles(10)
    
    results = Enum.map(validation_puzzles, fn puzzle ->
      case solve_puzzle_with_model(puzzle, model_id) do
        {:ok, accuracy} -> accuracy
        {:error, _} -> 0.0
      end
    end)
    
    average_accuracy = Enum.sum(results) / length(results)
    
    %{
      accuracy: average_accuracy,
      puzzle_count: length(validation_puzzles),
      individual_results: results
    }
  end
end
```

### Enhanced LLM Actions with ART Integration

```elixir
defmodule AriaArc.Domain do
  # Enhanced pattern analysis using ART-trained models
  @action
  def analyze_pattern_with_art(state, %{grid: grid, context: context, puzzle_id: puzzle_id}) do
    # Get current ART-trained model
    model_id = AriaArc.ModelManager.get_active_model()
    
    # Format conversation for ART model
    conversation = [
      %{
        "role" => "user",
        "content" => """
        Analyze this ARC puzzle grid to identify transformation patterns:
        
        Grid: #{format_grid_for_art(grid)}
        Context: #{context}
        
        Use the analyze_pattern tool to systematically examine the grid for visual and logical patterns.
        """
      }
    ]
    
    case AriaArc.ARTClient.complete_with_tools(model_id, conversation) do
      {:ok, response} ->
        # Parse tool calls and results from ART response
        {analysis, tool_calls} = parse_art_response(response)
        
        # Track reasoning step for future ART training
        reasoning_step = %{
          action: :analyze_pattern,
          input: %{grid: grid, context: context, focus_area: extract_focus_area(tool_calls)},
          output: analysis,
          tool_calls: tool_calls,
          model_used: model_id,
          timestamp: DateTime.utc_now()
        }
        
        new_state = state
        |> AriaState.RelationalState.add_fact("pattern", "analysis", analysis)
        |> AriaState.RelationalState.add_fact("reasoning", "chain", [reasoning_step])
        |> AriaState.RelationalState.add_fact("art", "puzzle_id", puzzle_id)
        
        {:ok, new_state}
      {:error, reason} ->
        {:error, "ART pattern analysis failed: #{reason}"}
    end
  end
  
  # Enhanced search with ART-guided strategy
  @action
  def search_with_art_guidance(state, %{search_budget: budget, focus_area: focus}) do
    model_id = AriaArc.ModelManager.get_active_model()
    pattern_analysis = AriaState.RelationalState.get_fact(state, "pattern", "analysis")
    
    conversation = [
      %{
        "role" => "user",
        "content" => """
        Based on this pattern analysis, guide the computational search for transformations:
        
        Pattern Analysis: #{pattern_analysis}
        Search Budget: #{budget} evaluations
        Focus Area: #{focus}
        
        Use the search_transformations tool to find promising transformation approaches.
        """
      }
    ]
    
    case AriaArc.ARTClient.complete_with_tools(
