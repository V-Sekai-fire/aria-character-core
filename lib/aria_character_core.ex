defmodule AriaCharacterCore do
  @moduledoc "AriaCharacterCore is a comprehensive character AI system that provides:\n\n- Hybrid planning capabilities through AriaEngine\n- RDF knowledge base management through AriaTown  \n- Workflow execution and management through AriaWorkflow\n- Web coordination interface through AriaCoordinate\n- Authentication and security services\n- Storage and file management\n- Monitoring and telemetry\n- AI/ML interpretation services\n\nThis module consolidates all the functionality that was previously distributed\nacross multiple umbrella applications into a single, cohesive application.\n"
  @doc "Returns the version of AriaCharacterCore.\n"
  def version do
    "0.2.0"
  end
end