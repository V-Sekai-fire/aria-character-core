# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTown.IRIHelpers do
  @moduledoc "Helper functions for generating chibifire.com IRIs (Internationalized Resource Identifiers).\nProvides consistent URL generation for all entities in the knowledge base.\n"
  @base_url "https://chibifire.com/"
  def npc_iri(name) when is_atom(name) do
    npc_iri(Atom.to_string(name))
  end

  def npc_iri(name) do
    RDF.iri(@base_url <> "npc/" <> to_string(name))
  end

  def location_iri(name) when is_atom(name) do
    location_iri(Atom.to_string(name))
  end

  def location_iri(name) do
    RDF.iri(@base_url <> "locations/" <> to_string(name))
  end

  def activity_iri(name) when is_atom(name) do
    activity_iri(Atom.to_string(name))
  end

  def activity_iri(name) do
    RDF.iri(@base_url <> "activities/" <> to_string(name))
  end

  def topic_iri(name) when is_atom(name) do
    topic_iri(Atom.to_string(name))
  end

  def topic_iri(name) do
    RDF.iri(@base_url <> "topics/" <> to_string(name))
  end

  def conversation_iri(id) do
    RDF.iri(@base_url <> "conversations/" <> to_string(id))
  end

  def event_iri(id) do
    RDF.iri(@base_url <> "events/" <> to_string(id))
  end

  def extract_name(iri) when is_binary(iri) do
    iri |> String.replace(@base_url, "") |> String.split("/") |> List.last()
  end

  def extract_name(%RDF.IRI{value: iri_string}) do
    extract_name(iri_string)
  end

  def is_npc_iri?(iri) do
    String.contains?(to_string(iri), "/npc/")
  end

  def is_location_iri?(iri) do
    String.contains?(to_string(iri), "/locations/")
  end

  def is_activity_iri?(iri) do
    String.contains?(to_string(iri), "/activities/")
  end

  def is_topic_iri?(iri) do
    String.contains?(to_string(iri), "/topics/")
  end

  def is_conversation_iri?(iri) do
    String.contains?(to_string(iri), "/conversations/")
  end
end
