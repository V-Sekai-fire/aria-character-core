# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule FlowBehaviour do
  @moduledoc """
  Behaviour defining the interface for stream processing functionality.
  
  This allows aria_engine to work with different flow processing implementations
  without being tightly coupled to AriaFlow. This follows dependency inversion
  principles and makes testing much easier.
  """

  @doc """
  Create a new processing pipeline with the given name and options.
  """
  @callback create_pipeline(name :: atom(), opts :: keyword()) :: {:ok, pid()} | {:error, term()}

  @doc """
  Process data through a pipeline with convergence processing.
  """
  @callback process_with_convergence(pipeline :: atom(), data :: list(), opts :: keyword()) :: map()

  @doc """
  Create a processing element with the given name, type, and options.
  """
  @callback create_element(name :: atom(), type :: atom(), opts :: keyword()) :: {:ok, pid()} | {:error, term()}

  @doc """
  Start a processing element with the given options.
  """
  @callback start_element(name :: atom(), opts :: keyword()) :: :ok | {:error, term()}

  @doc """
  Link two elements together through their pads.
  """
  @callback link_elements(source_element :: atom(), source_pad :: atom(), sink_element :: atom(), sink_pad :: atom()) :: :ok | {:error, term()}

  @doc """
  Send a buffer to an element's input pad.
  """
  @callback send_buffer(element_name :: atom(), pad_name :: atom(), buffer :: term()) :: :ok | {:error, term()}
end
