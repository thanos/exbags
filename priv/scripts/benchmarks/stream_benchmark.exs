# Stream vs Eager performance benchmark

defmodule StreamBenchmarks do
  @moduledoc """
  Performance benchmarks comparing ExBags stream vs eager operations.
  """

  def run_benchmarks do
    large_data = generate_data(50000)
    {map1, map2, _, _} = large_data

    IO.puts("Running Stream vs Eager Performance Comparison...")
    IO.puts("ExBags Stream vs Eager Operations")
    IO.puts("=" |> String.duplicate(60))

    IO.puts("\n📊 Large Dataset (50,000 items)")
    IO.puts("-" |> String.duplicate(40))

    Benchee.run(%{
      "ExBags.intersect (eager)" => fn -> ExBags.intersect(map1, map2) end,
      "ExBags.intersect_stream" => fn -> ExBags.intersect_stream(map1, map2) |> Enum.to_list() end,
      "ExBags.difference (eager)" => fn -> ExBags.difference(map1, map2) end,
      "ExBags.difference_stream" => fn -> ExBags.difference_stream(map1, map2) |> Enum.to_list() end,
      "ExBags.symmetric_difference (eager)" => fn -> ExBags.symmetric_difference(map1, map2) end,
      "ExBags.symmetric_difference_stream" => fn -> ExBags.symmetric_difference_stream(map1, map2) |> Enum.to_list() end
    }, time: 2, memory_time: 2)

    # Reconcile comparison (special handling for tuple return)
    IO.puts("\n📊 Reconcile Operations (50,000 items)")
    IO.puts("-" |> String.duplicate(40))

    Benchee.run(%{
      "ExBags.reconcile (eager)" => fn -> ExBags.reconcile(map1, map2) end,
      "ExBags.reconcile_stream (first 100)" => fn -> 
        {stream1, stream2, stream3} = ExBags.reconcile_stream(map1, map2)
        {stream1 |> Enum.take(100) |> Enum.to_list(),
         stream2 |> Enum.take(100) |> Enum.to_list(),
         stream3 |> Enum.take(100) |> Enum.to_list()}
      end
    }, time: 2, memory_time: 2)
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

    {map1, map2, nil, nil}
  end
end

# Run benchmarks
StreamBenchmarks.run_benchmarks()
