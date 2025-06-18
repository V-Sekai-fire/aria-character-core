# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTown.IRIHelpers do
  @moduledoc """
  Helper functions for generating chibifire.com IRIs (Internationalized Resource Identifiers).
  Provides consistent URL generation for all entities in the knowledge base.
  """
  
  @base_url "https://chibifire.com/"
  
  def npc_iri(name) when is_atom(name), do: npc_iri(Atom.to_string(name))
  def npc_iri(name), do: RDF.iri(@base_url <> "npc/" <> to_string(name))
  
  def location_iri(name) when is_atom(name), do: location_iri(Atom.to_string(name))
  def location_iri(name), do: RDF.iri(@base_url <> "locations/" <> to_string(name))
  
  def activity_iri(name) when is_atom(name), do: activity_iri(Atom.to_string(name))
  def activity_iri(name), do: RDF.iri(@base_url <> "activities/" <> to_string(name))
  
  def topic_iri(name) when is_atom(name), do: topic_iri(Atom.to_string(name))
  def topic_iri(name), do: RDF.iri(@base_url <> "topics/" <> to_string(name))
  
  def conversation_iri(id), do: RDF.iri(@base_url <> "conversations/" <> to_string(id))
  
  def event_iri(id), do: RDF.iri(@base_url <> "events/" <> to_string(id))
  
  # Extract entity name from IRI
  def extract_name(iri) when is_binary(iri) do
    iri
    |> String.replace(@base_url, "")
    |> String.split("/")
    |> List.last()
  end
  
  def extract_name(%RDF.IRI{value: iri_string}) do
    extract_name(iri_string)
  end
  
  # Check if IRI belongs to a specific type
  def is_npc_iri?(iri), do: String.contains?(to_string(iri), "/npc/")
  def is_location_iri?(iri), do: String.contains?(to_string(iri), "/locations/")
  def is_activity_iri?(iri), do: String.contains?(to_string(iri), "/activities/")
  def is_topic_iri?(iri), do: String.contains?(to_string(iri), "/topics/")
  def is_conversation_iri?(iri), do: String.contains?(to_string(iri), "/conversations/")
end
