# Intersect benchmark comparing Map, MapSet, and ExBags

defmodule IntersectBenchmarks do
  @moduledoc """
  Performance benchmarks comparing intersect operations across Map, MapSet, and ExBags.
  """

  def run_benchmarks do
    # Generate test data
    small_data = generate_data(100)
    medium_data = generate_data(1000)
    large_data = generate_data(10000)

    IO.puts("Running Intersect Performance Comparison...")
    IO.puts("Map vs MapSet vs ExBags")
    IO.puts("=" |> String.duplicate(60))

    # Small dataset
    {map1_small, map2_small, mapset1_small, mapset2_small} = small_data
    IO.puts("\n📊 Small Dataset (100 items)")
    IO.puts("-" |> String.duplicate(40))
    run_intersect_comparison(map1_small, map2_small, mapset1_small, mapset2_small)

    # Medium dataset
    {map1_medium, map2_medium, mapset1_medium, mapset2_medium} = medium_data
    IO.puts("\n📊 Medium Dataset (1,000 items)")
    IO.puts("-" |> String.duplicate(40))
    run_intersect_comparison(map1_medium, map2_medium, mapset1_medium, mapset2_medium)

    # Large dataset
    {map1_large, map2_large, mapset1_large, mapset2_large} = large_data
    IO.puts("\n📊 Large Dataset (10,000 items)")
    IO.puts("-" |> String.duplicate(40))
    run_intersect_comparison(map1_large, map2_large, mapset1_large, mapset2_large)
  end

  defp generate_data(size) do
    # Generate maps with random keys and values
    map1 = for i <- 1..size, into: %{} do
      key = :"key_#{i}"
      values = for _ <- 1..Enum.random(1..5), do: Enum.random(1..100)
      {key, values}
    end

    map2 = for i <- 1..size, into: %{} do
      key = :"key_#{i + div(size, 2)}"
      values = for _ <- 1..Enum.random(1..5), do: Enum.random(1..100)
      {key, values}
    end

    # Generate MapSets for comparison
    mapset1 = map1 |> Map.values() |> List.flatten() |> MapSet.new()
    mapset2 = map2 |> Map.values() |> List.flatten() |> MapSet.new()

    {map1, map2, mapset1, mapset2}
  end

  defp run_intersect_comparison(map1, map2, mapset1, mapset2) do
    # Map intersection (key-based)
    map_intersect = fn ->
      common_keys = Map.keys(map1) -- (Map.keys(map1) -- Map.keys(map2))
      Enum.into(common_keys, %{}, fn key ->
        {key, Map.get(map1, key)}
      end)
    end

    Benchee.run(%{
      "Map.intersect (keys only)" => map_intersect,
      "MapSet.intersection" => fn -> MapSet.intersection(mapset1, mapset2) end,
      "ExBags.intersect" => fn -> ExBags.intersect(map1, map2) end
    }, time: 2, memory_time: 2)
  end
end

# Run benchmarks
IntersectBenchmarks.run_benchmarks()
