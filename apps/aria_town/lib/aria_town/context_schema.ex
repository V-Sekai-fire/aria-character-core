defmodule AriaTown.ContextSchema do
  @moduledoc """
  Chibifire.com JSON-LD context schema definitions for semantic web compatibility.
  Provides RDF properties and classes with full URL identifiers.
  """
  
  @base_schema "https://chibifire.com/schema/"
  
  # JSON-LD Context for exports
  def get_context() do
    %{
      "@context" => %{
        # Classes
        "Person" => person(),
        "Location" => location(),
        "Activity" => activity(),
        "Conversation" => conversation(),
        
        # Relationship properties
        "knows" => knows(),
        "locatedAt" => located_at(),
        "engagedIn" => engaged_in(),
        "spokeWith" => spoke_with(),
        "heardAbout" => heard_about(),
        "plansTo" => plans_to(),
        "remembers" => remembers(),
        
        # Temporal properties
        "timeOfDay" => time_of_day(),
        "scheduledAt" => scheduled_at(),
        "timestamp" => timestamp(),
        
        # Social properties
        "personality" => personality(),
        "mood" => mood(),
        "priority" => priority(),
        "conflictsWith" => conflicts_with(),
        
        # Conversation properties
        "participants" => participants(),
        "about" => about(),
        "content" => content(),
        "source" => source()
      }
    }
  end
  
  # RDF Classes
  def person(), do: RDF.iri(@base_schema <> "Person")
  def location(), do: RDF.iri(@base_schema <> "Location")
  def activity(), do: RDF.iri(@base_schema <> "Activity")
  def conversation(), do: RDF.iri(@base_schema <> "Conversation")
  
  # Relationship Properties
  def knows(), do: RDF.iri(@base_schema <> "knows")
  def located_at(), do: RDF.iri(@base_schema <> "locatedAt")
  def engaged_in(), do: RDF.iri(@base_schema <> "engagedIn")
  def spoke_with(), do: RDF.iri(@base_schema <> "spokeWith")
  def heard_about(), do: RDF.iri(@base_schema <> "heardAbout")
  def plans_to(), do: RDF.iri(@base_schema <> "plansTo")
  def remembers(), do: RDF.iri(@base_schema <> "remembers")
  
  # Temporal Properties
  def time_of_day(), do: RDF.iri(@base_schema <> "timeOfDay")
  def scheduled_at(), do: RDF.iri(@base_schema <> "scheduledAt")
  def timestamp(), do: RDF.iri(@base_schema <> "timestamp")
  
  # Social Properties
  def personality(), do: RDF.iri(@base_schema <> "personality")
  def mood(), do: RDF.iri(@base_schema <> "mood")
  def priority(), do: RDF.iri(@base_schema <> "priority")
  def conflicts_with(), do: RDF.iri(@base_schema <> "conflictsWith")
  
  # Conversation Properties
  def participants(), do: RDF.iri(@base_schema <> "participants")
  def about(), do: RDF.iri(@base_schema <> "about")
  def content(), do: RDF.iri(@base_schema <> "content")
  def source(), do: RDF.iri(@base_schema <> "source")
end
