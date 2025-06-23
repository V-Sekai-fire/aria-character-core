defmodule AriaEngine.PngGenerator do
  @moduledoc "Pure Elixir PNG generation for schedule timeline visualization.\nGenerates Gantt chart images without external dependencies.\n"
  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>
  @colors %{
    background: {255, 255, 255},
    grid: {200, 200, 200},
    text: {0, 0, 0},
    a_phase: {52, 152, 219},
    b_phase: {46, 204, 113},
    c_phase: {230, 126, 34},
    d_phase: {155, 89, 182},
    e_phase: {231, 76, 60},
    critical: {192, 57, 43},
    default: {149, 165, 166}
  }
  def generate_timeline_png(schedule, filename \\ nil) do
    if length(schedule) == 0 do
      {:error, "Empty schedule"}
    else
      max_time = calculate_max_time(schedule)
      activity_count = length(schedule)
      time_unit_width = 30
      activity_height = 20
      margin_left = 80
      margin_top = 30
      margin_bottom = 20
      width = margin_left + max_time * time_unit_width + 20
      height = margin_top + activity_count * activity_height + margin_bottom

      pixel_data =
        generate_pixel_data(schedule, width, height, %{
          time_unit_width: time_unit_width,
          activity_height: activity_height,
          margin_left: margin_left,
          margin_top: margin_top
        })

      png_binary = create_png_binary(width, height, pixel_data)
      output_filename = filename || generate_filename(schedule)
      output_path = Path.join("priv/schedule_images", output_filename)
      File.mkdir_p!("priv/schedule_images")

      case File.write(output_path, png_binary) do
        :ok -> {:ok, output_path}
        {:error, reason} -> {:error, "Failed to write PNG: #{reason}"}
      end
    end
  end

  defp calculate_max_time(schedule) do
    Enum.max_by(schedule, fn activity ->
      start = Map.get(activity, "start_time", 0)
      duration = Map.get(activity, "duration", 1)
      start + duration
    end)
    |> then(fn activity ->
      start = Map.get(activity, "start_time", 0)
      duration = Map.get(activity, "duration", 1)
      start + duration
    end)
  end

  defp generate_pixel_data(schedule, width, height, layout) do
    background_color = @colors.background

    pixels =
      for _y <- 0..(height - 1), _x <- 0..(width - 1) do
        background_color
      end

    pixel_array =
      pixels
      |> Enum.chunk_every(width)
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {row, y}, acc ->
        row_map =
          row
          |> Enum.with_index()
          |> Enum.reduce(%{}, fn {pixel, x}, row_acc -> Map.put(row_acc, x, pixel) end)

        Map.put(acc, y, row_map)
      end)

    pixel_array = draw_time_grid(pixel_array, width, height, layout)
    sorted_schedule = Enum.sort_by(schedule, fn activity -> Map.get(activity, "id", "") end)

    pixel_array =
      sorted_schedule
      |> Enum.with_index()
      |> Enum.reduce(pixel_array, fn {activity, index}, acc ->
        draw_activity(acc, activity, index, layout)
      end)

    for y <- 0..(height - 1), x <- 0..(width - 1) do
      pixel_array[y][x]
    end
  end

  defp draw_time_grid(pixel_array, width, height, layout) do
    grid_color = @colors.grid
    max_time = div(width - layout.margin_left - 20, layout.time_unit_width)

    Enum.reduce(0..max_time, pixel_array, fn time, acc ->
      x = layout.margin_left + time * layout.time_unit_width

      if x < width do
        Enum.reduce(layout.margin_top..(height - 1), acc, fn y, inner_acc ->
          put_in(inner_acc[y][x], grid_color)
        end)
      else
        acc
      end
    end)
  end

  defp draw_activity(pixel_array, activity, index, layout) do
    id = Map.get(activity, "id", "?")
    start_time = Map.get(activity, "start_time", 0)
    duration = Map.get(activity, "duration", 1)
    color = get_activity_color(id)
    y_start = layout.margin_top + index * layout.activity_height + 2
    y_end = y_start + layout.activity_height - 4
    x_start = layout.margin_left + start_time * layout.time_unit_width + 2
    x_end = x_start + duration * layout.time_unit_width - 4

    Enum.reduce(y_start..y_end, pixel_array, fn y, acc ->
      Enum.reduce(x_start..x_end, acc, fn x, inner_acc ->
        if x >= 0 and x < map_size(inner_acc[0]) and y >= 0 and y < map_size(inner_acc) do
          put_in(inner_acc[y][x], color)
        else
          inner_acc
        end
      end)
    end)
  end

  defp get_activity_color(id) do
    cond do
      String.starts_with?(id, "A") -> @colors.a_phase
      String.starts_with?(id, "B") -> @colors.b_phase
      String.starts_with?(id, "C") -> @colors.c_phase
      String.starts_with?(id, "D") -> @colors.d_phase
      String.starts_with?(id, "E") -> @colors.e_phase
      true -> @colors.default
    end
  end

  defp create_png_binary(width, height, pixel_data) do
    palette = create_palette()

    indexed_data =
      Enum.map(pixel_data, fn {r, g, b} -> find_palette_index({r, g, b}, palette) end)

    ihdr = create_ihdr_chunk(width, height)
    plte = create_plte_chunk(palette)
    idat = create_idat_chunk(indexed_data, width)
    iend = create_iend_chunk()
    @png_signature <> ihdr <> plte <> idat <> iend
  end

  defp create_palette do
    [
      @colors.background,
      @colors.grid,
      @colors.text,
      @colors.a_phase,
      @colors.b_phase,
      @colors.c_phase,
      @colors.d_phase,
      @colors.e_phase,
      @colors.critical,
      @colors.default
    ]
  end

  defp find_palette_index(color, palette) do
    case Enum.find_index(palette, fn pal_color -> pal_color == color end) do
      nil -> 0
      index -> index
    end
  end

  defp create_ihdr_chunk(width, height) do
    data = <<width::32, height::32, 8::8, 3::8, 0::8, 0::8, 0::8>>
    create_chunk("IHDR", data)
  end

  defp create_plte_chunk(palette) do
    data = Enum.map_join(palette, "", fn {r, g, b} -> <<r::8, g::8, b::8>> end)
    create_chunk("PLTE", data)
  end

  defp create_idat_chunk(indexed_data, width) do
    rows =
      indexed_data
      |> Enum.chunk_every(width)
      |> Enum.map(fn row -> [0 | row] end)
      |> List.flatten()
      |> Enum.map_join("", &<<&1::8>>)

    compressed = :zlib.compress(rows)
    create_chunk("IDAT", compressed)
  end

  defp create_iend_chunk do
    create_chunk("IEND", "")
  end

  defp create_chunk(type, data) do
    length = byte_size(data)
    crc = :erlang.crc32(type <> data)
    <<length::32, type::binary, data::binary, crc::32>>
  end

  defp generate_filename(schedule) do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_string()
      |> String.replace(~r/[^\d]/, "")
      |> String.slice(0, 14)

    activity_count = length(schedule)
    "timeline_#{activity_count}_activities_#{timestamp}.png"
  end
end