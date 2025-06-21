# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormat.Constants do
  @moduledoc """
  Constants and type definitions for the ARCANA (Aria Content Archive) format.

  This module contains all magic numbers, format constants, and type definitions
  used across the casync format parsers. Based on desync source code analysis.
  """

  # Constants from desync source code (const.go) - exported as macros for guards
  defmacro ca_format_index, do: 0x96824D9C7B129FF9
  defmacro ca_format_table, do: 0xE75B9E112F17417D
  defmacro ca_format_table_tail_marker, do: 0x4B4F050E5549ECD1

  # CATAR format constants - exported as macros for guards
  defmacro ca_format_entry, do: 0x1396FABCEA5BBB51
  defmacro ca_format_user, do: 0xF453131AAEEACCB3
  defmacro ca_format_group, do: 0x25EB6AC969396A52
  defmacro ca_format_xattr, do: 0xB8157091F80BC486
  defmacro ca_format_acl_user, do: 0x297DC88B2EF12FAF
  defmacro ca_format_acl_group, do: 0x36F2ACB56CB3DD0B
  defmacro ca_format_acl_group_obj, do: 0x23047110441F38F3
  defmacro ca_format_acl_default, do: 0xFE3EEDA6823C8CD0
  defmacro ca_format_acl_default_user, do: 0xBDF03DF9BD010A91
  defmacro ca_format_acl_default_group, do: 0xA0CB1168782D1F51
  defmacro ca_format_fcaps, do: 0xF7267DB0AFED0629
  defmacro ca_format_selinux, do: 0x46FAF0602FD26C59
  defmacro ca_format_filename, do: 0x6DBB6EBCB3161F0B
  defmacro ca_format_symlink, do: 0x664A6FB6830E0D6C
  defmacro ca_format_device, do: 0xAC3DACE369DFE643
  defmacro ca_format_payload, do: 0x8B9E1D93D6DCFFC9
  defmacro ca_format_goodbye, do: 0xDFD35C5E8327C403
  defmacro ca_format_goodbye_tail_marker, do: 0x57446FA533702943

  # Compression types - exported as macros for guards
  defmacro compression_none, do: 0
  defmacro compression_zstd, do: 1

  # Feature flags for UID/GID encoding - exported as macros for guards
  defmacro ca_format_with_16_bit_uids, do: 0x1
  defmacro ca_format_with_32_bit_uids, do: 0x2

  @type format_type :: :caibx | :caidx | :cacnk | :catar
  @type compression_type :: :none | :zstd | :unknown
  @type catar_element_type :: :entry | :filename | :payload | :symlink | :device | :goodbye | :user | :group | :selinux | :xattr | :metadata

  @type chunk_item :: %{
    chunk_id: binary(),
    offset: non_neg_integer(),
    size: non_neg_integer(),
    flags: non_neg_integer()
  }

  @type table_item :: %{
    offset: non_neg_integer(),
    chunk_id: binary()
  }

  @type index_header :: %{
    version: pos_integer(),
    total_size: non_neg_integer(),
    chunk_count: non_neg_integer()
  }

  @type chunk_header :: %{
    compressed_size: non_neg_integer(),
    uncompressed_size: non_neg_integer(),
    compression: compression_type(),
    flags: non_neg_integer()
  }

  @type catar_element :: %{
    required(:type) => catar_element_type(),
    optional(atom()) => any()
  }

end
