defmodule ExBagsBenchmarks do
  @moduledoc """
  Main benchmark runner that executes all performance tests.
  """

  def run_all_benchmarks do
    IO.puts("🚀 Running All ExBags Performance Benchmarks")
    IO.puts("=" |> String.duplicate(60))

    # Run intersect benchmarks
    IO.puts("\n1️⃣ Intersect Performance Comparison")
    Code.eval_file("priv/scripts/benchmarks/intersect_benchmark.exs")

    # Run stream benchmarks
    IO.puts("\n2️⃣ Stream vs Eager Performance Comparison")
    Code.eval_file("priv/scripts/benchmarks/stream_benchmark.exs")

    IO.puts("\n✅ All benchmarks completed!")
  end

  def run_intersect_benchmarks do
    Code.eval_file("priv/scripts/benchmarks/intersect_benchmark.exs")
  end

  def run_stream_benchmarks do
    Code.eval_file("priv/scripts/benchmarks/stream_benchmark.exs")
  end
end

# Run all benchmarks by default
ExBagsBenchmarks.run_all_benchmarks()
