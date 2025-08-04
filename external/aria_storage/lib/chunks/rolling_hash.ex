# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Chunks.RollingHash do
  @moduledoc "Rolling hash implementation using buzhash algorithm.\n\nThis module implements the buzhash rolling hash algorithm that's fully compatible\nwith the Go implementation of desync/casync. It uses the same hash table values\nand boundary detection algorithm to produce identical chunking results.\n"
  import Bitwise
  @rolling_hash_window_size 48
  @hash_table [
    1_166_796_626,
    3_238_480_076,
    4_223_458_232,
    1_844_271_976,
    2_970_256_053,
    550_983_240,
    3_754_255_967,
    2_822_932_481,
    2_126_467_473,
    2_215_720_391,
    1_707_889_587,
    671_766_908,
    385_221_205,
    3_347_889_214,
    692_327_925,
    3_107_509_396,
    3_968_189_670,
    3_084_074_716,
    3_846_812_996,
    4_260_210_090,
    2_284_581_511,
    823_554_940,
    89_561_430,
    3_905_691_496,
    134_655_070,
    580_994_115,
    355_040_784,
    1_355_845_863,
    1_269_174_127,
    4_024_037_799,
    1_549_568_092,
    2_185_768_851,
    2_617_080_932,
    188_641_910,
    4_066_938_487,
    2_410_515_132,
    2_958_071_144,
    4_054_688_415,
    2_772_368_894,
    3_408_600_320,
    4_071_221_638,
    1_684_226_859,
    2_500_411_473,
    1_512_192_722,
    2_615_689_243,
    1_642_428_875,
    441_805_332,
    1_480_654_274,
    2_455_887_350,
    3_454_010_043,
    1_380_133_808,
    3_205_969_726,
    2_071_732_783,
    693_497_110,
    2_668_677_721,
    3_896_558_793,
    3_433_814_022,
    341_065_524,
    341_983_610,
    222_961_564,
    142_530_853,
    3_623_416_396,
    1_933_100_069,
    3_481_716_981,
    2_979_096_013,
    2_559_689_619,
    844_334_252,
    50_873_757,
    2_249_465_214,
    3_374_453_098,
    3_808_405_174,
    1_408_576_237,
    752_378_263,
    4_122_604_696,
    3_207_699_599,
    3_762_364_334,
    2_541_662_604,
    3_631_679_862,
    2_553_497_194,
    3_329_548_159,
    2_351_529_285,
    2_359_594_278,
    3_298_744_546,
    1_933_899_892,
    1_433_369_031,
    1_797_647_085,
    2_688_428_866,
    4_136_593_060,
    2_391_476_642,
    4_074_825_258,
    221_943_814,
    2_536_105_107,
    2_356_326_652,
    369_857_782,
    1_158_565_181,
    2_050_100_869,
    3_203_985_633,
    567_752_275,
    1_312_659_322,
    511_392_041,
    482_789_145,
    3_192_360_275,
    2_373_265_417,
    3_872_965_318,
    660_539_538,
    3_366_765_171,
    1_287_787_904,
    3_972_310_551,
    4_126_654_064,
    3_885_311_114,
    928_657_385,
    1_112_895_670,
    2_291_719_416,
    3_693_975_492,
    17_174_859,
    911_065_647,
    504_147_231,
    3_194_191_932,
    1_600_780_994,
    1_297_807_983,
    465_625_013,
    4_213_650_825,
    245_661_563,
    1_008_479_056,
    565_356_850,
    1_796_350_973,
    803_669_672,
    4_189_940_962,
    2_724_783_694,
    3_918_001_286,
    1_051_522_403,
    480_379_276,
    1_709_277_736,
    570_897_930,
    1_473_189_653,
    885_226_795,
    529_480_926,
    2_478_200_783,
    832_575_997,
    3_869_161_257,
    2_345_302_939,
    1_285_381_101,
    662_617_775,
    3_772_315_822,
    3_511_714_332,
    825_759_857,
    2_948_854_192,
    2_457_711_400,
    3_915_317_164,
    811_222_973,
    1_114_350_427,
    305_377_087,
    1_751_800_707,
    1_356_886_757,
    3_654_531_882,
    2_347_746_421,
    1_216_286_182,
    3_364_749_193,
    3_177_598_302,
    2_535_152_920,
    1_672_562_759,
    3_620_979_150,
    2_136_489_203,
    1_925_958_409,
    3_234_899_996,
    2_141_405_851,
    3_910_502_939,
    576_627_098,
    3_637_157_539,
    3_345_199_746,
    3_138_151_233,
    34_308_755,
    3_570_215_325,
    1_490_003_960,
    2_444_553_811,
    937_742_656,
    2_515_301_964,
    821_521_158,
    1_592_167_716,
    1_738_311_265,
    2_753_132_994,
    4_072_018_564,
    1_336_677_493,
    182_143_481,
    426_932_771,
    363_324_276,
    3_292_141_781,
    1_068_608_115,
    875_546_133,
    2_454_456_211,
    3_202_537_456,
    2_317_852_137,
    1_252_185_868,
    3_796_751_231,
    3_196_464_139,
    394_011_330,
    1_401_480_686,
    3_448_403_216,
    4_177_638_653,
    3_686_874_556,
    1_812_704_859,
    1_693_444_295,
    1_219_502_201,
    2_150_832_713,
    3_393_030_886,
    4_082_393_488,
    4_275_507_339,
    3_298_530_331,
    851_113_129,
    3_951_245_898,
    2_292_445_605,
    982_633_994,
    1_019_379_105,
    1_897_064_068,
    1_244_698_289,
    932_468_556,
    2_747_840_243,
    488_716_609,
    1_846_160_896,
    590_641_649,
    256_694_319,
    1_620_307_410,
    1_568_481_438,
    1_179_640_601,
    3_571_231_902,
    230_180_299,
    4_217_260_995,
    3_760_549_089,
    167_464_657,
    152_354_334,
    2_780_672_707,
    3_337_312_187,
    808_584_016,
    1_060_732_561,
    2_792_853_948,
    2_260_471_340,
    4_020_283_362,
    3_925_833_027,
    3_878_904_108,
    3_515_189_627,
    849_236_872,
    2_447_188_843,
    785_059_219,
    4_107_807_293,
    901_103_679,
    3_840_280_304,
    95_557_699,
    934_566_244,
    1_593_778_932,
    1_613_231_308,
    1_998_031_676,
    2_924_507_441,
    2_079_836_860,
    4_190_211_430,
    1_497_030_245,
    3_646_807_825
  ]
  @type hash_value :: non_neg_integer()
  @doc "Get the rolling hash window size.\n"
  @spec window_size() :: pos_integer()
  def window_size do
    @rolling_hash_window_size
  end

  @doc "Calculate buzhash for a window of data.\n\nThe window must be exactly the window size (48 bytes).\n"
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

  @doc "Update an existing buzhash value by removing one byte and adding another.\n\nThis efficiently updates the rolling hash when the window slides forward.\nImplementation matches desync Go code exactly.\n"
  @spec update_buzhash(hash_value(), byte(), byte()) :: hash_value()
  def update_buzhash(hash, out_byte, in_byte) do
    out_table_value = Enum.at(@hash_table, out_byte)
    in_table_value = Enum.at(@hash_table, in_byte)
    rolled_hash = rol32(hash, 1)
    rolled_out = rol32(out_table_value, @rolling_hash_window_size)
    rolled_hash |> Bitwise.bxor(rolled_out) |> Bitwise.bxor(in_table_value)
  end

  @doc "Calculate the discriminator value from the average chunk size.\n\nThis uses the exact formula from desync/casync to ensure compatible chunking.\nThe discriminator determines boundary frequency and therefore average chunk size.\n"
  @spec discriminator_from_avg(pos_integer()) :: pos_integer()
  def discriminator_from_avg(avg) do
    trunc(avg / (-1.42888852e-7 * avg + 1.33237515))
  end

  @doc "Find chunk boundary in data using rolling hash algorithm.\n\nReturns the position where the chunk should end.\n"
  @spec find_chunk_boundary(
          binary(),
          non_neg_integer(),
          pos_integer(),
          pos_integer(),
          pos_integer()
        ) :: non_neg_integer()
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
        find_boundary_starting_at(data, min_end, max_end, discriminator)
      end
    end
  end

  @spec rol32(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp rol32(value, shift) do
    shift = rem(shift, 32)
    mask32 = 4_294_967_295
    (value <<< shift ||| value >>> (32 - shift)) &&& mask32
  end

  @spec find_boundary_starting_at(binary(), non_neg_integer(), non_neg_integer(), pos_integer()) ::
          non_neg_integer()
  defp find_boundary_starting_at(data, start_pos, max_end, discriminator) do
    data_size = byte_size(data)
    window_start = start_pos - @rolling_hash_window_size + 1

    if window_start < 0 or start_pos >= data_size do
      max_end
    else
      window_data = binary_part(data, window_start, @rolling_hash_window_size)
      initial_hash = calculate_buzhash(window_data)
      rolling_search(data, start_pos, max_end, initial_hash, discriminator)
    end
  end

  @spec rolling_search(
          binary(),
          non_neg_integer(),
          non_neg_integer(),
          hash_value(),
          pos_integer()
        ) :: non_neg_integer()
  defp rolling_search(data, pos, max_end, _hash, _discriminator)
       when pos > max_end or pos >= byte_size(data) do
    max_end
  end

  defp rolling_search(data, pos, max_end, hash, discriminator) do
    if pos > max_end or pos >= byte_size(data) do
      max_end
    else
      if pos + 1 >= byte_size(data) do
        max_end
      else
        out_byte = :binary.at(data, pos - @rolling_hash_window_size + 1)
        in_byte = :binary.at(data, pos + 1)
        new_hash = update_buzhash(hash, out_byte, in_byte)
        new_pos = pos + 1

        if rem(new_hash, discriminator) == discriminator - 1 do
          new_pos + 1
        else
          rolling_search(data, new_pos, max_end, new_hash, discriminator)
        end
      end
    end
  end
end
