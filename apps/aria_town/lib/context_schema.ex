# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTown.ContextSchema do
  @moduledoc "Chibifire.com JSON-LD context schema definitions for semantic web compatibility.\nProvides RDF properties and classes with full URL identifiers.\n"
  @base_schema "https://chibifire.com/schema/"
  def get_context() do
    %{
      "@context" => %{
        "Person" => person(),
        "Location" => location(),
        "Activity" => activity(),
        "Conversation" => conversation(),
        "knows" => knows(),
        "locatedAt" => located_at(),
        "engagedIn" => engaged_in(),
        "spokeWith" => spoke_with(),
        "heardAbout" => heard_about(),
        "plansTo" => plans_to(),
        "remembers" => remembers(),
        "timeOfDay" => time_of_day(),
        "scheduledAt" => scheduled_at(),
        "timestamp" => timestamp(),
        "personality" => personality(),
        "mood" => mood(),
        "priority" => priority(),
        "conflictsWith" => conflicts_with(),
        "participants" => participants(),
        "about" => about(),
        "content" => content(),
        "source" => source()
      }
    }
  end

  def person() do
    RDF.iri(@base_schema <> "Person")
  end

  def location() do
    RDF.iri(@base_schema <> "Location")
  end

  def activity() do
    RDF.iri(@base_schema <> "Activity")
  end

  def conversation() do
    RDF.iri(@base_schema <> "Conversation")
  end

  def knows() do
    RDF.iri(@base_schema <> "knows")
  end

  def located_at() do
    RDF.iri(@base_schema <> "locatedAt")
  end

  def engaged_in() do
    RDF.iri(@base_schema <> "engagedIn")
  end

  def spoke_with() do
    RDF.iri(@base_schema <> "spokeWith")
  end

  def heard_about() do
    RDF.iri(@base_schema <> "heardAbout")
  end

  def plans_to() do
    RDF.iri(@base_schema <> "plansTo")
  end

  def remembers() do
    RDF.iri(@base_schema <> "remembers")
  end

  def time_of_day() do
    RDF.iri(@base_schema <> "timeOfDay")
  end

  def scheduled_at() do
    RDF.iri(@base_schema <> "scheduledAt")
  end

  def timestamp() do
    RDF.iri(@base_schema <> "timestamp")
  end

  def personality() do
    RDF.iri(@base_schema <> "personality")
  end

  def mood() do
    RDF.iri(@base_schema <> "mood")
  end

  def priority() do
    RDF.iri(@base_schema <> "priority")
  end

  def conflicts_with() do
    RDF.iri(@base_schema <> "conflictsWith")
  end

  def participants() do
    RDF.iri(@base_schema <> "participants")
  end

  def about() do
    RDF.iri(@base_schema <> "about")
  end

  def content() do
    RDF.iri(@base_schema <> "content")
  end

  def source() do
    RDF.iri(@base_schema <> "source")
  end
end
