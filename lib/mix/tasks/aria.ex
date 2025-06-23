defmodule Mix.Tasks.Aria do
  @moduledoc "AriaEngine command-line interface.\n\n## Available Commands\n\n  * `mix aria.schedule` - Schedule activities using AriaEngine scheduler\n  * `mix aria.validate` - Validate scheduling solutions by comparing solvers\n  * `mix aria.pipeline` - Manage AriaEngine processing pipelines\n\n## Quick Examples\n\n    # Schedule activities from JSON files\n    mix aria.schedule --name \"project_tasks\" --activities tasks.json --entities workers.json\n\n    # Train scheduling\n    mix aria.schedule --name \"trains05\" --train-mode --verbose 2\n\n    # Validate scheduling with generated problem\n    mix aria.validate --problem \"test_scaling\" --activities 3 --compare\n\n    # Start a processing pipeline\n    mix aria.pipeline start --topology echo_pipeline\n\n    # List active pipelines\n    mix aria.pipeline list\n\n## Getting Help\n\nUse `--help` with any command for detailed usage information:\n\n    mix aria.schedule --help\n    mix aria.validate --help\n    mix aria.pipeline --help\n\n## About AriaEngine\n\nAriaEngine is a temporal planning and scheduling system that provides:\n\n- Activity scheduling with resource management\n- Multi-solver validation and comparison\n- Pipeline-based processing architecture\n- Train scheduling optimization\n- Constraint satisfaction solving\n\nFor more information, see the project documentation.\n"
  use Mix.Task
  @shortdoc "AriaEngine command-line interface"
  def run(args) do
    case args do
      ["--help"] ->
        Mix.shell().info(@moduledoc)

      ["help"] ->
        Mix.shell().info(@moduledoc)

      [] ->
        Mix.shell().info(@moduledoc)

      [command | _] ->
        Mix.shell().error("Unknown command: #{command}")
        Mix.shell().info("Use 'mix aria --help' for available commands")
        System.halt(1)
    end
  end
end