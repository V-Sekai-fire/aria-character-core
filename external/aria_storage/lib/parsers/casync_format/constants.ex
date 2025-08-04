# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Parsers.CasyncFormat.Constants do
  @moduledoc "Constants and type definitions for the ARCANA (Aria Content Archive) format.\n\nThis module contains all magic numbers, format constants, and type definitions\nused across the casync format parsers. Based on desync source code analysis.\n"
  defmacro ca_format_index do
    10_845_316_187_136_630_777
  end

  defmacro ca_format_table do
    16_671_092_242_283_708_797
  end

  defmacro ca_format_table_tail_marker do
    5_426_561_635_123_326_161
  end

  defmacro ca_format_entry do
    1_411_591_222_519_905_105
  end

  defmacro ca_format_user do
    17_605_436_373_646_101_683
  end

  defmacro ca_format_group do
    2_732_395_012_216_678_994
  end

  defmacro ca_format_xattr do
    13_264_632_049_723_753_606
  end

  defmacro ca_format_acl_user do
    2_989_766_227_757_445_039
  end

  defmacro ca_format_acl_group do
    3_959_416_917_624_872_203
  end

  defmacro ca_format_acl_group_obj do
    2_523_266_005_910_632_691
  end

  defmacro ca_format_acl_default do
    18_320_341_633_595_116_752
  end

  defmacro ca_format_acl_default_user do
    13_686_507_410_406_050_449
  end

  defmacro ca_format_acl_default_group do
    11_586_373_606_731_226_961
  end

  defmacro ca_format_fcaps do
    17_809_059_974_302_467_625
  end

  defmacro ca_format_selinux do
    5_114_664_622_742_465_625
  end

  defmacro ca_format_filename do
    7_907_035_327_516_516_107
  end

  defmacro ca_format_symlink do
    7_370_826_569_818_705_260
  end

  defmacro ca_format_device do
    12_411_266_240_836_789_827
  end

  defmacro ca_format_payload do
    10_060_511_138_394_472_393
  end

  defmacro ca_format_goodbye do
    16_128_336_251_540_980_739
  end

  defmacro ca_format_goodbye_tail_marker do
    6_288_273_735_039_330_627
  end

  defmacro compression_none do
    0
  end

  defmacro compression_zstd do
    1
  end

  defmacro ca_format_with_16_bit_uids do
    1
  end

  defmacro ca_format_with_32_bit_uids do
    2
  end

  @type format_type :: :caibx | :caidx | :cacnk | :catar
  @type compression_type :: :none | :zstd | :unknown
  @type catar_element_type ::
          :entry
          | :filename
          | :payload
          | :symlink
          | :device
          | :goodbye
          | :user
          | :group
          | :selinux
          | :xattr
          | :metadata
  @type chunk_item :: %{
          chunk_id: binary(),
          offset: non_neg_integer(),
          size: non_neg_integer(),
          flags: non_neg_integer()
        }
  @type table_item :: %{offset: non_neg_integer(), chunk_id: binary()}
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
  @type catar_element :: %{required(:type) => catar_element_type(), optional(atom()) => any()}
end
