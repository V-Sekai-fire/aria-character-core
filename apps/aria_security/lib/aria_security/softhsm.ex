# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.SoftHSM do
  @moduledoc """
  SoftHSM integration module for managing PKCS#11 operations.

  This module provides a high-level interface for working with SoftHSM
  tokens, keys, and cryptographic operations through the PKCS#11 standard.
  """

  require Logger

  # Default SoftHSM configuration
  @default_library_path "/usr/lib64/pkcs11/libsofthsm2.so"
  @default_config_path "/etc/softhsm2.conf"
  @default_token_dir "/var/lib/softhsm/tokens"

  defstruct [
    :library_path,
    :config_path,
    :token_dir,
    :slot,
    :pin,
    :so_pin,
    :label
  ]

  @type t :: %__MODULE__{
    library_path: String.t(),
    config_path: String.t(),
    token_dir: String.t(),
    slot: non_neg_integer(),
    pin: String.t(),
    so_pin: String.t(),
    label: String.t()
  }

  @doc """
  Creates a new SoftHSM configuration struct.

  ## Options

  * `:library_path` - Path to the SoftHSM PKCS#11 library (default: #{@default_library_path})
  * `:config_path` - Path to the SoftHSM configuration file (default: #{@default_config_path})
  * `:token_dir` - Directory where SoftHSM tokens are stored (default: #{@default_token_dir})
  * `:slot` - PKCS#11 slot number (default: 0)
  * `:pin` - User PIN for token access (default: "1234")
  * `:so_pin` - Security Officer PIN (default: "1234")
  * `:label` - Token label (default: "OpenBao Token")

  ## Examples

      iex> AriaSecurity.SoftHSM.new()
      %AriaSecurity.SoftHSM{slot: 0, pin: "1234", ...}

      iex> AriaSecurity.SoftHSM.new(slot: 1, pin: "secret")
      %AriaSecurity.SoftHSM{slot: 1, pin: "secret", ...}
  """
  def new(opts \\ []) do
    %__MODULE__{
      library_path: Keyword.get(opts, :library_path, @default_library_path),
      config_path: Keyword.get(opts, :config_path, @default_config_path),
      token_dir: Keyword.get(opts, :token_dir, @default_token_dir),
      slot: Keyword.get(opts, :slot, 0),
      pin: Keyword.get(opts, :pin, "1234"),
      so_pin: Keyword.get(opts, :so_pin, "1234"),
      label: Keyword.get(opts, :label, "OpenBao Token")
    }
  end

  @doc """
  Initializes a new SoftHSM token.

  This will create a new token in the specified slot with the given label and PINs.

  ## Examples

      iex> hsm = AriaSecurity.SoftHSM.new()
      iex> AriaSecurity.SoftHSM.initialize_token(hsm)
      {:ok, %{slot: 0, label: "OpenBao Token"}}
  """
  def initialize_token(%__MODULE__{} = hsm) do
    Logger.info("Initializing SoftHSM token: #{hsm.label} in slot #{hsm.slot}")

    # Set environment variable for SoftHSM config
    System.put_env("SOFTHSM2_CONF", hsm.config_path)

    # Use --free flag to let SoftHSM assign the slot automatically
    cmd_args = [
      "--init-token",
      "--free",
      "--label", hsm.label,
      "--so-pin", hsm.so_pin,
      "--pin", hsm.pin
    ]

    case System.cmd("softhsm2-util", cmd_args, stderr_to_stdout: true) do
      {output, 0} ->
        Logger.info("SoftHSM token initialized successfully: #{output}")

        # Extract the assigned slot from output
        assigned_slot = extract_slot_from_output(output)

        {:ok, %{
          slot: assigned_slot || hsm.slot,
          label: hsm.label,
          output: output
        }}

      {error, exit_code} ->
        Logger.error("Failed to initialize SoftHSM token: #{error}")
        {:error, {:initialization_failed, exit_code, error}}
    end
  end

  @doc """
  Lists all available PKCS#11 slots and tokens.

  ## Examples

      iex> hsm = AriaSecurity.SoftHSM.new()
      iex> AriaSecurity.SoftHSM.list_slots(hsm)
      {:ok, [%{slot: 0, label: "OpenBao Token", ...}]}
  """
  def list_slots(%__MODULE__{} = hsm) do
    System.put_env("SOFTHSM2_CONF", hsm.config_path)

    case System.cmd("softhsm2-util", ["--show-slots"], stderr_to_stdout: true) do
      {output, 0} ->
        slots = parse_slots_output(output)
        {:ok, slots}

      {error, exit_code} ->
        Logger.error("Failed to list SoftHSM slots: #{error}")
        {:error, {:list_slots_failed, exit_code, error}}
    end
  end

  @doc """
  Generates an RSA key pair in the specified token slot.

  ## Options

  * `:key_size` - RSA key size in bits (default: 2048)
  * `:key_label` - Label for the generated key (default: "openbao-seal-key")
  * `:extractable` - Whether the key should be extractable (default: false)

  ## Examples

      iex> hsm = AriaSecurity.SoftHSM.new()
      iex> AriaSecurity.SoftHSM.generate_rsa_keypair(hsm)
      {:ok, %{key_label: "openbao-seal-key", key_size: 2048}}
  """
  def generate_rsa_keypair(%__MODULE__{} = hsm, opts \\ []) do
    key_size = Keyword.get(opts, :key_size, 2048)
    key_label = Keyword.get(opts, :key_label, "openbao-seal-key")
    extractable = Keyword.get(opts, :extractable, false)

    Logger.info("Generating RSA-#{key_size} key pair: #{key_label} in slot #{hsm.slot}")

    cmd_args = [
      "--module", hsm.library_path,
      "--login",
      "--pin", hsm.pin,
      "--slot", to_string(hsm.slot),
      "--keypairgen",
      "--key-type", "rsa:#{key_size}",
      "--label", key_label
    ]

    cmd_args = if extractable do
      cmd_args ++ ["--extractable"]
    else
      cmd_args
    end

    case System.cmd("pkcs11-tool", cmd_args, stderr_to_stdout: true) do
      {output, 0} ->
        Logger.info("RSA key pair generated successfully: #{output}")

        {:ok, %{
          key_label: key_label,
          key_size: key_size,
          slot: hsm.slot,
          extractable: extractable,
          output: output
        }}

      {error, exit_code} ->
        Logger.error("Failed to generate RSA key pair: #{error}")
        {:error, {:key_generation_failed, exit_code, error}}
    end
  end

  @doc """
  Lists objects (keys, certificates) in the specified token slot.

  ## Examples

      iex> hsm = AriaSecurity.SoftHSM.new()
      iex> AriaSecurity.SoftHSM.list_objects(hsm)
      {:ok, [%{type: "Private Key", label: "openbao-seal-key", ...}]}
  """
  def list_objects(%__MODULE__{} = hsm) do
    cmd_args = [
      "--module", hsm.library_path,
      "--login",
      "--pin", hsm.pin,
      "--slot", to_string(hsm.slot),
      "--list-objects"
    ]

    case System.cmd("pkcs11-tool", cmd_args, stderr_to_stdout: true) do
      {output, 0} ->
        objects = parse_objects_output(output)
        {:ok, objects}

      {error, exit_code} ->
        Logger.error("Failed to list PKCS#11 objects: #{error}")
        {:error, {:list_objects_failed, exit_code, error}}
    end
  end

  @doc """
  Deletes all tokens and reinitializes SoftHSM.

  **WARNING: This is a destructive operation that will delete all existing tokens and keys.**

  ## Examples

      iex> hsm = AriaSecurity.SoftHSM.new()
      iex> AriaSecurity.SoftHSM.reset_hsm(hsm)
      {:ok, %{message: "SoftHSM reset successfully"}}
  """
  def reset_hsm(%__MODULE__{} = hsm) do
    Logger.warning("Resetting SoftHSM - this will destroy all existing tokens and keys!")

    # Remove all tokens
    case File.rm_rf(hsm.token_dir) do
      {:ok, _} ->
        Logger.info("Removed all SoftHSM tokens from #{hsm.token_dir}")

        # Recreate token directory
        case File.mkdir_p(hsm.token_dir) do
          :ok ->
            Logger.info("Recreated SoftHSM token directory")
            {:ok, %{message: "SoftHSM reset successfully"}}

          {:error, reason} ->
            Logger.error("Failed to recreate token directory: #{reason}")
            {:error, {:directory_creation_failed, reason}}
        end

      {:error, reason} ->
        Logger.error("Failed to remove token directory: #{reason}")
        {:error, {:directory_removal_failed, reason}}
    end
  end

  @doc """
  Gets the current SoftHSM configuration.

  ## Examples

      iex> hsm = AriaSecurity.SoftHSM.new()
      iex> AriaSecurity.SoftHSM.get_config(hsm)
      {:ok, %{library_path: "/usr/lib64/pkcs11/libsofthsm2.so", ...}}
  """
  def get_config(%__MODULE__{} = hsm) do
    config = %{
      library_path: hsm.library_path,
      config_path: hsm.config_path,
      token_dir: hsm.token_dir,
      slot: hsm.slot,
      label: hsm.label,
      environment: %{
        softhsm2_conf: System.get_env("SOFTHSM2_CONF")
      }
    }

    {:ok, config}
  end

  # Private helper functions

  defp extract_slot_from_output(output) do
    # Look for patterns like "reassigned to slot 0" or "slot 0"
    case Regex.run(~r/(?:reassigned to slot|slot)\s+(\d+)/i, output) do
      [_match, slot_str] -> String.to_integer(slot_str)
      nil -> nil
    end
  end

  defp parse_slots_output(output) do
    # Parse the output of `softhsm2-util --show-slots`
    # This is a simplified parser - in practice, you might want more robust parsing
    output
    |> String.split("\n")
    |> Enum.filter(&String.contains?(&1, "Slot"))
    |> Enum.map(fn line ->
      # Extract slot number and other info
      case Regex.run(~r/Slot\s+(\d+)/i, line) do
        [_match, slot_str] ->
          %{
            slot: String.to_integer(slot_str),
            description: String.trim(line)
          }
        nil ->
          %{description: String.trim(line)}
      end
    end)
  end

  defp parse_objects_output(output) do
    # Parse the output of `pkcs11-tool --list-objects`
    # This is a simplified parser
    output
    |> String.split("\n")
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.map(fn line ->
      %{
        description: String.trim(line),
        type: extract_object_type(line)
      }
    end)
  end

  defp extract_object_type(line) do
    cond do
      String.contains?(line, "Private Key") -> "Private Key"
      String.contains?(line, "Public Key") -> "Public Key"
      String.contains?(line, "Certificate") -> "Certificate"
      String.contains?(line, "Secret Key") -> "Secret Key"
      true -> "Unknown"
    end
  end
end
