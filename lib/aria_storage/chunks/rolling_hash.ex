# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Chunks.RollingHash do
  @moduledoc """
  Rolling hash implementation using buzhash algorithm.
  
  This module implements the buzhash rolling hash algorithm that's fully compatible
  with the Go implementation of desync/casync. It uses the same hash table values
  and boundary detection algorithm to produce identical chunking results.
  """

  import Bitwise

  @rolling_hash_window_size 48

  # Buzhash hash table (from desync)
  @hash_table [
    0x458BE752,
    0xC10748CC,
    0xFBBCDBB8,
    0x6DED5B68,
    0xB10A82B5,
    0x20D75648,
    0xDFC5665F,
    0xA8428801,
    0x7EBF5191,
    0x841135C7,
    0x65CC53B3,
    0x280A597C,
    0x16F60255,
    0xC78CBC3E,
    0x294415F5,
    0xB938D494,
    0xEC85C4E6,
    0xB7D33EDC,
    0xE549B544,
    0xFDEDA5AA,
    0x882BF287,
    0x3116737C,
    0x05569956,
    0xE8CC1F68,
    0x0806AC5E,
    0x22A14443,
    0x15297E10,
    0x50D090E7,
    0x4BA60F6F,
    0xEFD9F1A7,
    0x5C5C885C,
    0x82482F93,
    0x9BFD7C64,
    0x0B3E7276,
    0xF2688E77,
    0x8FAD8ABC,
    0xB0509568,
    0xF1ADA29F,
    0xA53EFDFE,
    0xCB2B1D00,
    0xF2A9E986,
    0x6463432B,
    0x95094051,
    0x5A223AD2,
    0x9BE8401B,
    0x61E579CB,
    0x1A556A14,
    0x5840FDC2,
    0x9261DDF6,
    0xCDE002BB,
    0x52432BB0,
    0xBF17373E,
    0x7B7C222F,
    0x2955ED16,
    0x9F10CA59,
    0xE840C4C9,
    0xCCABD806,
    0x14543F34,
    0x1462417A,
    0x0D4A1F9C,
    0x087ED925,
    0xD7F8F24C,
    0x7338C425,
    0xCF86C8F5,
    0xB19165CD,
    0x9891C393,
    0x325384AC,
    0x0308459D,
    0x86141D7E,
    0xC922116A,
    0xE2FFA6B6,
    0x53F52AED,
    0x2CD86197,
    0xF5B9F498,
    0xBF319C8F,
    0xE0411FAE,
    0x977EB18C,
    0xD8770976,
    0x9833466A,
    0xC674DF7F,
    0x8C297D45,
    0x8CA48D26,
    0xC49ED8E2,
    0x7344F874,
    0x556F79C7,
    0x6B25EAED,
    0xA03E2B42,
    0xF68F66A4,
    0x8E8B09A2,
    0xF2E0E62A,
    0x0D3A9806,
    0x9729E493,
    0x8C72B0FC,
    0x160B94F6,
    0x450E4D3D,
    0x7A320E85,
    0xBEF8F0E1,
    0x21D73653,
    0x4E3D977A,
    0x1E7B3929,
    0x1CC6C719,
    0xBE478D53,
    0x8D752809,
    0xE6D8C2C6,
    0x275F0892,
    0xC8ACC273,
    0x4CC21580,
    0xECC4A617,
    0xF5F7BE70,
    0xE795248A,
    0x375A2FE9,
    0x425570B6,
    0x8898DCF8,
    0xDC2D97C4,
    0x0106114B,
    0x364DC22F,
    0x1E0CAD1F,
    0xBE63803C,
    0x5F69FAC2,
    0x4D5AFA6F,
    0x1BC0DFB5,
    0xFB273589,
    0x0EA47F7B,
    0x3C1C2B50,
    0x21B2A932,
    0x6B1223FD,
    0x2FE706A8,
    0xF9BD6CE2,
    0xA268E64E,
    0xE987F486,
    0x3EACF563,
    0x1CA2018C,
    0x65E18228,
    0x2207360A,
    0x57CF1715,
    0x34C37D2B,
    0x1F8F3CDE,
    0x93B657CF,
    0x31A019FD,
    0xE69EB729,
    0x8BCA7B9B,
    0x4C9D5BED,
    0x277EBEAF,
    0xE0D8F8AE,
    0xD150821C,
    0x31381871,
    0xAFC3F1B0,
    0x927DB328,
    0xE95EFFAC,
    0x305A47BD,
    0x426BA35B,
    0x1233AF3F,
    0x686A5B83,
    0x50E072E5,
    0xD9D3BB2A,
    0x8BEFC475,
    0x487F0DE6,
    0xC88DFF89,
    0xBD664D5E,
    0x971B5D18,
    0x63B14847,
    0xD7D3C1CE,
    0x7F583CF3,
    0x72CBCB09,
    0xC0D0A81C,
    0x7FA3429B,
    0xE9158A1B,
    0x225EA19A,
    0xD8CA9EA3,
    0xC763B282,
    0xBB0C6341,
    0x020B8293,
    0xD4CD299D,
    0x58CFA7F8,
    0x91B4EE53,
    0x37E4D140,
    0x95EC764C,
    0x30F76B06,
    0x5EE68D24,
    0x679C8661,
    0xA41979C2,
    0xF2B61284,
    0x4FAC1475,
    0x0ADB49F9,
    0x19727A23,
    0x15A7E374,
    0xC43A18D5,
    0x3FB1AA73,
    0x342FC615,
    0x924C0793,
    0xBEE2D7F0,
    0x8A279DE9,
    0x4AA2D70C,
    0xE24DD37F,
    0xBE862C0B,
    0x177C22C2,
    0x5388E5EE,
    0xCD8A7510,
    0xF901B4FD,
    0xDBC13DBC,
    0x6C0BAE5B,
    0x64EFE8C7,
    0x48B02079,
    0x80331A49,
    0xCA3D8AE6,
    0xF3546190,
    0xFED7108B,
    0xC49B941B,
    0x32BAF4A9,
    0xEB833A4A,
    0x88A3F1A5,
    0x3A91CE0A,
    0x3CC27DA1,
    0x7112E684,
    0x4A3096B1,
    0x3794574C,
    0xA3C8B6F3,
    0x1D213941,
    0x6E0A2E00,
    0x233479F1,
    0x0F4CD82F,
    0x6093EDD2,
    0x5D7D209E,
    0x464FE319,
    0xD4DCAC9E,
    0x0DB845CB,
    0xFB5E4BC3,
    0xE0256CE1,
    0x09FB4ED1,
    0x0914BE1E,
    0xA5BDB2C3,
    0xC6EB57BB,
    0x30320350,
    0x3F397E91,
    0xA67791BC,
    0x86BC0E2C,
    0xEFA0A7E2,
    0xE9FF7543,
    0xE733612C,
    0xD185897B,
    0x329E5388,
    0x91DD236B,
    0x2ECB0D93,
    0xF4D82A3D,
    0x35B5C03F,
    0xE4E606F0,
    0x05B21843,
    0x37B45964,
    0x5EFF22F4,
    0x6027F4CC,
    0x77178B3C,
    0xAE507131,
    0x7BF7CABC,
    0xF9C18D66,
    0x593ADE65,
    0xD95DDF11
  ]

  @type hash_value :: non_neg_integer()

  @doc """
  Get the rolling hash window size.
  """
  @spec window_size() :: pos_integer()
  def window_size, do: @rolling_hash_window_size

  @doc """
  Calculate buzhash for a window of data.
  
  The window must be exactly the window size (48 bytes).
  """
  @spec calculate_buzhash(binary()) :: hash_value()
  def calculate_buzhash(window) when byte_size(window) == @rolling_hash_window_size do
    window
    |> :binary.bin_to_list()
    |> Enum.with_index()
    |> Enum.reduce(0, fn {byte, idx}, acc ->
      table_value = Enum.at(@hash_table, byte)
      shift = @rolling_hash_window_size - idx - 1
      rotated = rol32(table_value, shift)
      Bitwise.bxor(acc, rotated)
    end)
  end

  @doc """
  Update an existing buzhash value by removing one byte and adding another.

  This efficiently updates the rolling hash when the window slides forward.
  Implementation matches desync Go code exactly.
  """
  @spec update_buzhash(hash_value(), byte(), byte()) :: hash_value()
  def update_buzhash(hash, out_byte, in_byte) do
    out_table_value = Enum.at(@hash_table, out_byte)
    in_table_value = Enum.at(@hash_table, in_byte)

    # Roll hash left by 1 (same as desync)
    rolled_hash = rol32(hash, 1)

    # XOR out the influence of outgoing byte (rolled by window size)
    rolled_out = rol32(out_table_value, @rolling_hash_window_size)

    # Apply the rolling hash update formula from desync
    rolled_hash
    |> Bitwise.bxor(rolled_out)
    |> Bitwise.bxor(in_table_value)
  end

  @doc """
  Calculate the discriminator value from the average chunk size.

  This uses the exact formula from desync/casync to ensure compatible chunking.
  The discriminator determines boundary frequency and therefore average chunk size.
  """
  @spec discriminator_from_avg(pos_integer()) :: pos_integer()
  def discriminator_from_avg(avg) do
    # Implement the exact formula from desync/casync
    # Go's uint32() conversion is equivalent to Elixir's trunc/1 function
    trunc(avg / (-1.42888852e-7 * avg + 1.33237515))
  end

  @doc """
  Find chunk boundary in data using rolling hash algorithm.
  
  Returns the position where the chunk should end.
  """
  @spec find_chunk_boundary(binary(), non_neg_integer(), pos_integer(), pos_integer(), pos_integer()) :: non_neg_integer()
  def find_chunk_boundary(data, start_pos, min_size, max_size, discriminator) do
    data_size = byte_size(data)
    min_end = start_pos + min_size
    max_end = min(start_pos + max_size, data_size)

    if min_end >= data_size do
      data_size
    else
      if min_end + @rolling_hash_window_size > data_size do
        data_size
      else
        # In desync, the rolling hash starts from the minimum position
        # and we look for boundaries byte by byte
        find_boundary_starting_at(data, min_end, max_end, discriminator)
      end
    end
  end

  # Private functions

  @spec rol32(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp rol32(value, shift) do
    shift = rem(shift, 32)
    mask32 = 0xFFFFFFFF
    (value <<< shift ||| value >>> (32 - shift)) &&& mask32
  end

  # Start the rolling hash algorithm from the minimum position
  @spec find_boundary_starting_at(binary(), non_neg_integer(), non_neg_integer(), pos_integer()) :: non_neg_integer()
  defp find_boundary_starting_at(data, start_pos, max_end, discriminator) do
    data_size = byte_size(data)

    # In desync, we need to have a full window before we can start checking for boundaries
    # The window ends at start_pos, so it starts at (start_pos - window_size + 1)
    window_start = start_pos - @rolling_hash_window_size + 1

    if window_start < 0 or start_pos >= data_size do
      # Can't form a proper window, return max_end
      max_end
    else
      # Get the initial window ending at start_pos
      window_data = binary_part(data, window_start, @rolling_hash_window_size)
      initial_hash = calculate_buzhash(window_data)

      # Start rolling search from start_pos (don't check boundary at initial position)
      # This matches desync behavior: update hash first, then check boundary
      rolling_search(data, start_pos, max_end, initial_hash, discriminator)
    end
  end

  # Continue the rolling hash search with corrected positioning
  @spec rolling_search(binary(), non_neg_integer(), non_neg_integer(), hash_value(), pos_integer()) :: non_neg_integer()
  defp rolling_search(data, pos, max_end, _hash, _discriminator)
       when pos > max_end or pos >= byte_size(data) do
    max_end
  end

  defp rolling_search(data, pos, max_end, hash, discriminator) do
    # First, check if we've reached the end
    if pos > max_end or pos >= byte_size(data) do
      max_end
    else
      # Check if we can form the next window (need pos+1 to be valid)
      if pos + 1 >= byte_size(data) do
        max_end
      else
        # Get the bytes that are leaving and entering the window for next position
        # Current window ends at pos, next window will end at pos+1
        # Byte leaving the window
        out_byte = :binary.at(data, pos - @rolling_hash_window_size + 1)
        # Byte entering the window
        in_byte = :binary.at(data, pos + 1)

        # Update the hash to reflect the next window position
        new_hash = update_buzhash(hash, out_byte, in_byte)
        new_pos = pos + 1

        # Check if the new position is a boundary (matching desync order)
        # In desync, the boundary position includes the byte that caused the boundary
        if rem(new_hash, discriminator) == discriminator - 1 do
          # Return position after the boundary-causing byte (matching desync)
          new_pos + 1
        else
          # Continue rolling forward
          rolling_search(data, new_pos, max_end, new_hash, discriminator)
        end
      end
    end
  end
end
