defmodule Mix.Tasks.Aria.Schedule do
  @moduledoc "Schedule activities using AriaEngine scheduler.\n\n## Usage\n\n    mix aria.schedule --name \"my_schedule\" --activities activities.json\n    mix aria.schedule --name \"trains05\" --train-mode\n    mix aria.schedule --help\n\n## Options\n\n  * `--name` - Schedule name (required)\n  * `--activities` - Path to JSON file containing activities\n  * `--entities` - Path to JSON file containing entities\n  * `--resources` - Path to JSON file containing resources\n  * `--constraints` - Path to JSON file containing constraints\n  * `--train-mode` - Use train scheduling mode with trains05 data\n  * `--simulation` - Run in simulation mode\n  * `--verbose` - Verbosity level (0-3, default: 1)\n  * `--log-activities` - Log activity execution events\n  * `--help` - Show this help\n\n## Examples\n\n    # Schedule custom activities\n    mix aria.schedule --name \"project_tasks\" --activities tasks.json --entities workers.json\n\n    # Train scheduling\n    mix aria.schedule --name \"trains05\" --train-mode --verbose 2\n\n    # Simulation mode\n    mix aria.schedule --name \"test_schedule\" --activities test.json --simulation\n"
  use Mix.Task
  require Logger
  @shortdoc "Schedule activities using AriaEngine scheduler"
  @switches name: :string,
            activities: :string,
            entities: :string,
            resources: :string,
            constraints: :string,
            train_mode: :boolean,
            simulation: :boolean,
            verbose: :integer,
            log_activities: :boolean,
            help: :boolean
  @aliases n: :name,
           a: :activities,
           e: :entities,
           r: :resources,
           c: :constraints,
           t: :train_mode,
           s: :simulation,
           v: :verbose,
           l: :log_activities,
           h: :help
  def run(args) do
    {opts, _argv, _errors} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      Mix.shell().info(@moduledoc)
    end

    unless opts[:name] do
      Mix.shell().error("Error: --name is required")
      Mix.shell().info("Use --help for usage information")
      System.halt(1)
    end

    Mix.Task.run("app.start")
    schedule_name = opts[:name]

    cond do
      opts[:train_mode] ->
        handle_train_scheduling(schedule_name, opts)

      opts[:activities] ->
        handle_custom_scheduling(schedule_name, opts)

      true ->
        Mix.shell().error("Error: Either --activities or --train-mode must be specified")
        System.halt(1)
    end
  end

  defp handle_train_scheduling(schedule_name, opts) do
    Mix.shell().info("🚂 Processing train scheduling request: #{schedule_name}")
    train_data = AriaEngine.TrainSchedulingConverter.convert_trains05_to_schedule_activities()

    case call_scheduler(train_data, opts) do
      {:ok, result} ->
        Mix.shell().info("✅ Train schedule generated successfully")
        display_results(result, "trains05_scheduling")

      {:error, reason} ->
        Mix.shell().error("❌ Train scheduling failed: #{reason}")
        System.halt(1)
    end
  end

  defp handle_custom_scheduling(schedule_name, opts) do
    Mix.shell().info("📋 Processing custom scheduling request: #{schedule_name}")
    activities = load_json_file(opts[:activities], "activities")
    entities = load_json_file(opts[:entities], "entities") || []
    resources = load_json_file(opts[:resources], "resources") || %{}
    constraints = load_json_file(opts[:constraints], "constraints") || %{}

    params = %{
      "schedule_name" => schedule_name,
      "activities" => activities,
      "entities" => entities,
      "resources" => resources,
      "constraints" => constraints
    }

    case call_scheduler(params, opts) do
      {:ok, result} ->
        Mix.shell().info("✅ Schedule generated successfully")
        display_results(result, "custom_scheduling")

      {:error, reason} ->
        Mix.shell().error("❌ Scheduling failed: #{reason}")
        System.halt(1)
    end
  end

  defp call_scheduler(params, opts) do
    schedule_name = params["schedule_name"]
    activities = params["activities"] || []
    entities = params["entities"] || []
    resources = params["resources"] || %{}
    constraints = params["constraints"] || %{}
    simulation_mode = opts[:simulation] || false
    verbose = opts[:verbose] || 1
    activity_log = opts[:log_activities] || false
    Mix.shell().info("🔧 Calling AriaEngine.Scheduler.Core.schedule_with_enhanced_features")
    Mix.shell().info("🔧 Activities: #{length(activities)}, Entities: #{length(entities)}")

    activities_list =
      if is_list(activities) do
        activities
      else
        []
      end

    entities_list =
      if is_list(entities) do
        entities
      else
        []
      end

    base_datetime = ~U[2025-01-01 00:00:00Z]

    AriaEngine.Scheduler.Core.schedule_with_enhanced_features(
      schedule_name,
      activities_list,
      entities_list,
      resources,
      constraints,
      simulation_mode,
      activity_log,
      verbose,
      base_datetime
    )
  end

  defp load_json_file(nil, _type) do
    nil
  end

  defp load_json_file(path, type) do
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} ->
            Mix.shell().info("📁 Loaded #{type} from #{path}")
            data

          {:error, reason} ->
            Mix.shell().error("❌ Failed to parse JSON in #{path}: #{inspect(reason)}")
            System.halt(1)
        end

      {:error, reason} ->
        Mix.shell().error("❌ Failed to read #{path}: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp display_results(result, problem_type) do
    schedule = format_schedule_result(result)
    analysis = format_analysis_result(result)
    resource_utilization = format_resource_utilization(result)
    Mix.shell().info("\n📊 Scheduling Results:")
    Mix.shell().info("Problem Type: #{problem_type}")
    Mix.shell().info("Schedule Items: #{length(schedule)}")

    if analysis != %{} do
      Mix.shell().info("\n📈 Analysis:")
      Enum.each(analysis, fn {key, value} -> Mix.shell().info("  #{key}: #{inspect(value)}") end)
    end

    if resource_utilization != %{} do
      Mix.shell().info("\n🔧 Resource Utilization:")

      Enum.each(resource_utilization, fn {key, value} ->
        Mix.shell().info("  #{key}: #{inspect(value)}")
      end)
    end

    if length(schedule) > 0 do
      Mix.shell().info("\n📅 Schedule:")
      Enum.each(schedule, fn item -> Mix.shell().info("  #{inspect(item)}") end)
    end
  end

  defp format_schedule_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{schedule: schedule} -> schedule
      %{schedule: schedule} -> schedule
      _ -> []
    end
  end

  defp format_analysis_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{analysis: analysis} -> analysis
      %{analysis: analysis} -> analysis
      _ -> %{}
    end
  end

  defp format_resource_utilization(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{resource_utilization: utilization} -> utilization
      %{resource_utilization: utilization} -> utilization
      _ -> %{}
    end
  end
end