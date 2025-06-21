# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTown.JSONEncoders do
  @moduledoc """
  JSON encoder implementations for RDF and other external types.

  This module provides Jason.Encoder implementations for types that don't
  have built-in JSON serialization support, particularly RDF structures.
  """

  # Implement Jason.Encoder for RDF.IRI
  defimpl Jason.Encoder, for: RDF.IRI do
    def encode(%RDF.IRI{value: iri_string}, opts) do
      Jason.Encode.string(iri_string, opts)
    end
  end

  # Implement Jason.Encoder for RDF.Literal if needed
  defimpl Jason.Encoder, for: RDF.Literal do
    def encode(literal, opts) do
      Jason.Encode.string(to_string(literal), opts)
    end
  end

  # Implement Jason.Encoder for RDF.BlankNode if needed
  defimpl Jason.Encoder, for: RDF.BlankNode do
    def encode(%RDF.BlankNode{value: value}, opts) do
      Jason.Encode.string("_:#{value}", opts)
    end
  end
end
