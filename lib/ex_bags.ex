defmodule ExBags do
  @moduledoc """
  Duplicate bag (multiset) implementation for Elixir with set operations.

  ## Installation

  Add to your `mix.exs`:

  ```elixir
  def deps do
    [
      {:ex_bags, "~> 0.2.0"}
    ]
  end
  ```

  ## Overview

  ExBags implements duplicate bags that allow multiple values for the same key. Values are stored as lists, enabling tracking of multiple occurrences for each key.

  Use cases:
  - Data reconciliation and synchronization
  - Multiset operations and counting
  - Data analysis and comparison
  - Inventory management and tracking

  ## Core Bag Operations

  ### `new/0`

  Creates a new empty bag.

  ```elixir
  iex> ExBags.new()
  %{}
  ```y deps

  ### `put/3`

  Adds a value to the bag for the given key.

  ```elixir
  iex> bag = ExBags.new()
  iex> bag = ExBags.put(bag, :a, 1)
  iex> bag = ExBags.put(bag, :a, 2)
  iex> ExBags.get(bag, :a)
  [1, 2]
  ```

  ### `get/2`

  Gets all values for a given key from the bag.

  ```elixir
  iex> bag = %{a: [1, 2, 3], b: ["hello"]}
  iex> ExBags.get(bag, :a)
  [1, 2, 3]

  iex> bag = %{a: [1, 2, 3], b: ["hello"]}
  iex> ExBags.get(bag, :c)
  []
  ```

  ### `keys/1`

  Gets all keys from the bag.

  ```elixir
  iex> bag = %{a: [1, 2], b: [3], c: []}
  iex> ExBags.keys(bag) |> Enum.sort()
  [:a, :b, :c]
  ```

  ### `values/1`

  Gets all values from the bag, flattened into a single list.

  ```elixir
  iex> bag = %{a: [1, 2], b: [3, 4]}
  iex> ExBags.values(bag) |> Enum.sort()
  [1, 2, 3, 4]
  ```

  ### `update/3`

  Updates the values for a key in the bag using a function.

  ```elixir
  iex> bag = %{a: [1, 2, 3]}
  iex> ExBags.update(bag, :a, fn values -> Enum.map(values, &(&1 * 2)) end)
  %{a: [2, 4, 6]}
  ```

  ## Set Operations

  ### `intersect/2`

  Returns key-value pairs that exist in both bags. Values are returned as tuples containing values from each bag.

  ```elixir
  iex> ExBags.intersect(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
  %{b: {[2, 3], [2, 4]}}

  iex> ExBags.intersect(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1, 2], b: [2, 4]})
  %{a: {[1, 1, 2], [1, 2]}, b: {[2, 2, 3], [2, 4]}}
  ```

  ### `difference/2`

  Returns key-value pairs that exist in the first bag but not in the second bag.

  ```elixir
  iex> ExBags.difference(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
  %{a: [1, 2], b: [3]}

  iex> ExBags.difference(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1], b: [2]})
  %{a: [1, 2], b: [2, 3]}
  ```

  ### `symmetric_difference/2`

  Returns key-value pairs that exist in either bag but not in both.

  ```elixir
  iex> ExBags.symmetric_difference(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
  %{a: [1, 2], b: [3, 4], c: [5]}

  iex> ExBags.symmetric_difference(%{a: [1, 1, 2]}, %{a: [1, 2, 2]})
  %{a: [1, 2]}
  ```

  ### `reconcile/2`

  Performs reconciliation similar to SQL FULL OUTER JOIN. Returns a tuple of three bags:

  1. Common: Key-value pairs that exist in both bags
  2. Only first: Key-value pairs that exist only in the first bag
  3. Only second: Key-value pairs that exist only in the second bag

  ```elixir
  iex> ExBags.reconcile(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
  {%{b: [2]}, %{a: [1, 2], b: [3]}, %{b: [4], c: [5]}}

  iex> ExBags.reconcile(%{a: [1]}, %{b: [2]})
  {%{}, %{a: [1]}, %{b: [2]}}
  ```

  ## Stream Functions

  Memory-efficient stream versions for large datasets:

  ### `intersect_stream/2`, `difference_stream/2`, `symmetric_difference_stream/2`, `reconcile_stream/2`

  These functions return streams instead of bags.

  ```elixir
  iex> ExBags.intersect_stream(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]}) |> Enum.to_list() |> Enum.sort()
  [{:b, {[2, 3], [2, 4]}}]

  iex> large_bag1 = %{a: [1, 2], b: [3, 4], c: [5, 6]}
  iex> large_bag2 = %{b: [3, 5], c: [6, 7], d: [8, 9]}
  iex> stream = ExBags.intersect_stream(large_bag1, large_bag2)
  iex> _first_ten = stream |> Stream.take(10) |> Enum.to_list()

  iex> bag1 = %{a: [1, 2], b: [3, 4]}
  iex> bag2 = %{b: [3, 5], c: [6, 7]}
  iex> {common, only_first, only_second} = ExBags.reconcile_stream(bag1, bag2)
  iex> {Enum.to_list(common) |> Enum.sort(), Enum.to_list(only_first) |> Enum.sort(), Enum.to_list(only_second) |> Enum.sort()}
  ```

  ## Use Cases

  ### Inventory Management

  ```elixir
  inventory = ExBags.new()
  inventory = ExBags.put(inventory, :apples, "red")
  inventory = ExBags.put(inventory, :apples, "green")
  inventory = ExBags.put(inventory, :bananas, "yellow")

  ExBags.get(inventory, :apples)
  # ["red", "green"]

  common_items = ExBags.intersect(warehouse_inventory, store_inventory)
  ```

  ### Data Synchronization

  ```elixir
  local_data = %{users: ["alice", "bob"], sessions: ["session1", "session2"]}
  remote_data = %{users: ["alice", "charlie"], sessions: ["session2", "session3"]}

  {common, local_only, remote_only} = ExBags.reconcile(local_data, remote_data)
  # common: %{users: ["alice"], sessions: ["session2"]}
  # local_only: %{users: ["bob"], sessions: ["session1"]}
  # remote_only: %{users: ["charlie"], sessions: ["session3"]}
  ```

  ### Event Tracking

  ```elixir
  events = ExBags.new()
  events = ExBags.put(events, :user1, "login")
  events = ExBags.put(events, :user1, "view_page")
  events = ExBags.put(events, :user2, "login")

  common_events = ExBags.intersect(user_events, admin_events)
  ```

  ## Performance

  ExBags is optimized for duplicate bag operations with competitive performance characteristics:

  ### Intersect Performance Comparison

  | Dataset Size | MapSet.intersection | ExBags.intersect | Map.intersect (keys) |
  |--------------|-------------------|------------------|---------------------|
  | **100 items** | 475K ops/sec | 203K ops/sec (2.3x slower) | 47K ops/sec (10x slower) |
  | **1,000 items** | 697K ops/sec | 13K ops/sec (55x slower) | 2K ops/sec (315x slower) |
  | **10,000 items** | 702K ops/sec | 1K ops/sec (691x slower) | 135 ops/sec (5,198x slower) |

  ### Memory Usage Comparison

  | Dataset Size | MapSet | ExBags | Map (keys) |
  |--------------|--------|--------|------------|
  | **100 items** | 3.2 KB | 7.0 KB (2.2x) | 8.1 KB (2.6x) |
  | **1,000 items** | 2.3 KB | 69 KB (31x) | 97 KB (43x) |
  | **10,000 items** | 2.3 KB | 430 KB (191x) | 772 KB (342x) |

  ### Stream vs Eager Performance

  For large datasets (50,000 items), streams provide better performance:

  - **ExBags.intersect_stream**: 330 ops/sec
  - **ExBags.intersect (eager)**: 193 ops/sec (1.7x slower)
  - **Memory**: Streams use 4.0 MB vs 2.6 MB for eager (1.5x more)

  ### Performance Characteristics

  - **MapSet**: Fastest for simple set operations on flattened values
  - **ExBags**: Optimized for duplicate bag semantics with tuple-based results
  - **Map**: Slowest due to key iteration overhead
  - **Streams**: Better for large datasets, memory-efficient processing
  - **Time complexity**: O(n) where n is the number of keys
  - **Memory**: Scales with data size, streams reduce peak memory usage

  ## Testing

  ```bash
  mix test
  ```

  Test coverage:
  - 33 unit tests
  - 36 doctests
  - 22 property tests using StreamData
  - 100% code coverage

  Property testing validates functions with various inputs including different value types, empty bags, and large datasets.

  ### Coverage Reports

  Generate HTML coverage report:
  ```bash
  mix coveralls.html
  ```

  View the report in `cover/excoveralls.html`.

  ### Benchmarking

  Run performance benchmarks:
  ```bash
  # Run all benchmarks
  mix benchmark

  # Run specific benchmarks
  mix benchmark.intersect    # Compare Map, MapSet, ExBags intersect
  mix benchmark.stream       # Compare ExBags stream vs eager
  mix benchmark.all          # Run all benchmarks

  # Update README with current results
  mix run priv/scripts/update_readme_benchmarks.exs
  ```

  Compare ExBags with Map and MapSet operations across different dataset sizes.

  Available benchmark functions:
  - `ExBagsBenchmarks.run_intersect_benchmarks()` - Compare intersect performance
  - `ExBagsBenchmarks.run_stream_benchmarks()` - Compare stream vs eager performance

  ## Changelog

  See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and migration guides.

  ## License

  MIT License - see [LICENSE](LICENSE) file for details.
  """

  @doc """
  Creates a new empty bag.

  ## Examples

      iex> ExBags.new()
      %{}

  """
  @spec new() :: map()
  def new, do: %{}

  @doc """
  Adds a value to the bag for the given key.

  If the key doesn't exist, it creates a new list with the value.
  If the key exists, it appends the value to the existing list.

  ## Examples

      iex> bag = ExBags.new()
      iex> bag = ExBags.put(bag, :a, 1)
      iex> bag = ExBags.put(bag, :a, 2)
      iex> ExBags.get(bag, :a)
      [1, 2]

      iex> bag = ExBags.put(%{}, :b, "hello")
      iex> ExBags.get(bag, :b)
      ["hello"]

  """
  @spec put(map(), any(), any()) :: map()
  def put(bag, key, value) when is_map(bag) do
    case Map.get(bag, key) do
      nil -> Map.put(bag, key, [value])
      existing_values -> Map.put(bag, key, existing_values ++ [value])
    end
  end

  @doc """
  Gets all values for a given key from the bag.

  Returns an empty list if the key doesn't exist.

  ## Examples

      iex> bag = %{a: [1, 2, 3], b: ["hello"]}
      iex> ExBags.get(bag, :a)
      [1, 2, 3]

      iex> ExBags.get(%{a: [1, 2, 3], b: ["hello"]}, :c)
      []

  """
  @spec get(map(), any()) :: list()
  def get(bag, key) when is_map(bag) do
    Map.get(bag, key, [])
  end

  @doc """
  Gets all keys from the bag.

  ## Examples

      iex> bag = %{a: [1, 2], b: [3], c: []}
      iex> ExBags.keys(bag) |> Enum.sort()
      [:a, :b, :c]

  """
  @spec keys(map()) :: [any()]
  def keys(bag) when is_map(bag) do
    Map.keys(bag)
  end

  @doc """
  Gets all values from the bag, flattened into a single list.

  ## Examples

      iex> bag = %{a: [1, 2], b: [3, 4]}
      iex> ExBags.values(bag) |> Enum.sort()
      [1, 2, 3, 4]

  """
  @spec values(map()) :: list()
  def values(bag) when is_map(bag) do
    bag
    |> Map.values()
    |> List.flatten()
  end

  @doc """
  Updates the values for a key in the bag using a function.

  The function receives the current list of values and should return a new list.
  If the key doesn't exist, the function receives an empty list.

  ## Examples

      iex> bag = %{a: [1, 2, 3]}
      iex> ExBags.update(bag, :a, fn values -> Enum.map(values, &(&1 * 2)) end)
      %{a: [2, 4, 6]}

      iex> bag = %{}
      iex> ExBags.update(bag, :b, fn values -> values ++ [10] end)
      %{b: [10]}

  """
  @spec update(map(), any(), (list() -> list())) :: map()
  def update(bag, key, fun) when is_map(bag) and is_function(fun, 1) do
    current_values = Map.get(bag, key, [])
    new_values = fun.(current_values)
    Map.put(bag, key, new_values)
  end

  @doc """
  Returns a bag containing only the key-value pairs that exist in both bags.

  For duplicate bags, this finds the intersection of keys and returns tuples
  containing the values from both bags for each common key.

  ## Examples

      iex> ExBags.intersect(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
      %{b: {[2, 3], [2, 4]}}

      iex> ExBags.intersect(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1, 2], b: [2, 4]})
      %{a: {[1, 1, 2], [1, 2]}, b: {[2, 2, 3], [2, 4]}}

      iex> ExBags.intersect(%{}, %{a: [1]})
      %{}

  """
  @spec intersect(map(), map()) :: map()
  def intersect(bag1, bag2) when is_map(bag1) and is_map(bag2) do
    bag1
    |> Map.keys()
    |> Enum.filter(&Map.has_key?(bag2, &1))
    |> Enum.into(%{}, fn key ->
      values1 = Map.get(bag1, key, [])
      values2 = Map.get(bag2, key, [])
      {key, {values1, values2}}
    end)
  end

  # Helper function to find intersection of two value lists
  defp bag_intersection(list1, list2) do
    # Count occurrences in each list
    counts1 = Enum.frequencies(list1)
    counts2 = Enum.frequencies(list2)

    # Find common values and their minimum counts
    common_values = Map.keys(counts1) -- (Map.keys(counts1) -- Map.keys(counts2))

    common_values
    |> Enum.flat_map(fn value ->
      min_count = min(counts1[value], counts2[value])
      List.duplicate(value, min_count)
    end)
  end

  @doc """
  Returns a bag containing only the key-value pairs that exist in the first bag
  but not in the second bag.

  For duplicate bags, this finds the difference of values for each key.
  The result contains values from the first bag minus the values from the second bag.

  ## Examples

      iex> ExBags.difference(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
      %{a: [1, 2], b: [3]}

      iex> ExBags.difference(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1], b: [2]})
      %{a: [1, 2], b: [2, 3]}

      iex> ExBags.difference(%{}, %{a: [1]})
      %{}

  """
  @spec difference(map(), map()) :: map()
  def difference(bag1, bag2) when is_map(bag1) and is_map(bag2) do
    bag1
    |> Enum.into(%{}, fn {key, values1} ->
      values2 = Map.get(bag2, key, [])
      difference_values = bag_difference(values1, values2)
      {key, difference_values}
    end)
    |> Enum.reject(fn {_key, values} -> Enum.empty?(values) end)
    |> Map.new()
  end

  # Helper function to find difference of two value lists
  defp bag_difference(list1, list2) do
    # Count occurrences in each list
    counts1 = Enum.frequencies(list1)
    counts2 = Enum.frequencies(list2)

    # For each value in list1, subtract the count from list2
    counts1
    |> Enum.flat_map(fn {value, count1} ->
      count2 = Map.get(counts2, value, 0)
      remaining_count = max(0, count1 - count2)
      List.duplicate(value, remaining_count)
    end)
  end

  @doc """
  Returns a bag containing key-value pairs that exist in either bag but not in both.

  For duplicate bags, this finds the symmetric difference of values for each key.
  The result contains values that appear in one bag but not the other.

  ## Examples

      iex> ExBags.symmetric_difference(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
      %{a: [1, 2], b: [3, 4], c: [5]}

      iex> ExBags.symmetric_difference(%{a: [1, 1, 2]}, %{a: [1, 2, 2]})
      %{a: [1, 2]}

      iex> ExBags.symmetric_difference(%{a: [1, 2]}, %{c: [3, 4]})
      %{a: [1, 2], c: [3, 4]}

  """
  @spec symmetric_difference(map(), map()) :: map()
  def symmetric_difference(bag1, bag2) when is_map(bag1) and is_map(bag2) do
    keys1 = Map.keys(bag1)
    keys2 = Map.keys(bag2)

    only_in_bag1 = keys1 -- keys2
    only_in_bag2 = keys2 -- keys1
    common_keys = keys1 -- only_in_bag1

    # Keys only in bag1
    result1 = Enum.into(only_in_bag1, %{}, fn key -> {key, Map.get(bag1, key)} end)

    # Keys only in bag2
    result2 = Enum.into(only_in_bag2, %{}, fn key -> {key, Map.get(bag2, key)} end)

    # Common keys with symmetric difference of values
    result3 = common_keys
    |> Enum.into(%{}, fn key ->
      values1 = Map.get(bag1, key, [])
      values2 = Map.get(bag2, key, [])
      sym_diff_values = bag_symmetric_difference(values1, values2)
      {key, sym_diff_values}
    end)
    |> Enum.reject(fn {_key, values} -> Enum.empty?(values) end)
    |> Map.new()

    Map.merge(Map.merge(result1, result2), result3)
  end

  # Helper function to find symmetric difference of two value lists
  defp bag_symmetric_difference(list1, list2) do
    # Count occurrences in each list
    counts1 = Enum.frequencies(list1)
    counts2 = Enum.frequencies(list2)

    # All unique values
    all_values = Map.keys(counts1) ++ Map.keys(counts2) |> Enum.uniq()

    all_values
    |> Enum.flat_map(fn value ->
      count1 = Map.get(counts1, value, 0)
      count2 = Map.get(counts2, value, 0)
      diff_count = abs(count1 - count2)
      List.duplicate(value, diff_count)
    end)
  end

  @doc """
  Performs a reconciliation operation similar to SQL's FULL OUTER JOIN for duplicate bags.

  Returns a tuple of three bags:
  - First bag: key-value pairs that exist in both bags (intersection)
  - Second bag: key-value pairs that exist only in the first bag
  - Third bag: key-value pairs that exist only in the second bag

  ## Examples

      iex> ExBags.reconcile(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
      {%{b: [2]}, %{a: [1, 2], b: [3]}, %{b: [4], c: [5]}}

      iex> ExBags.reconcile(%{a: [1]}, %{b: [2]})
      {%{}, %{a: [1]}, %{b: [2]}}

      iex> ExBags.reconcile(%{a: [1, 2], b: [3]}, %{a: [1, 2], b: [3]})
      {%{a: [1, 2], b: [3]}, %{}, %{}}

  """
  @spec reconcile(map(), map()) :: {map(), map(), map()}
  def reconcile(bag1, bag2) when is_map(bag1) and is_map(bag2) do
    # For reconcile, we want the actual intersection of values, not tuples
    intersection = bag1
    |> Map.keys()
    |> Enum.filter(&Map.has_key?(bag2, &1))
    |> Enum.into(%{}, fn key ->
      values1 = Map.get(bag1, key, [])
      values2 = Map.get(bag2, key, [])
      intersection_values = bag_intersection(values1, values2)
      {key, intersection_values}
    end)
    |> Enum.reject(fn {_key, values} -> Enum.empty?(values) end)
    |> Map.new()

    only_in_bag1 = difference(bag1, bag2)
    only_in_bag2 = difference(bag2, bag1)

    {intersection, only_in_bag1, only_in_bag2}
  end

  @doc """
  Returns a stream of key-value pairs that exist in both maps.

  This is a memory-efficient version of `intersect/2` that returns a stream
  instead of a map. Useful for processing large maps without loading everything
  into memory.

  ## Examples

      iex> ExBags.intersect_stream(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]}) |> Enum.to_list() |> Enum.sort()
      [{:b, {[2, 3], [2, 4]}}]

      iex> ExBags.intersect_stream(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1, 2], b: [2, 4]}) |> Enum.to_list() |> Enum.sort()
      [{:a, {[1, 1, 2], [1, 2]}}, {:b, {[2, 2, 3], [2, 4]}}]

      iex> ExBags.intersect_stream(%{}, %{a: [1]}) |> Enum.to_list()
      []

  """
  @spec intersect_stream(map(), map()) :: Enumerable.t()
  def intersect_stream(bag1, bag2) when is_map(bag1) and is_map(bag2) do
    bag1
    |> Map.keys()
    |> Stream.filter(&Map.has_key?(bag2, &1))
    |> Stream.map(fn key ->
      values1 = Map.get(bag1, key, [])
      values2 = Map.get(bag2, key, [])
      {key, {values1, values2}}
    end)
  end

  @doc """
  Returns a stream of key-value pairs that exist in the first map but not in the second map.

  This is a memory-efficient version of `difference/2` that returns a stream
  instead of a map. Useful for processing large maps without loading everything
  into memory.

  ## Examples

      iex> ExBags.difference_stream(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]}) |> Enum.to_list() |> Enum.sort()
      [{:a, [1, 2]}, {:b, [3]}]

      iex> ExBags.difference_stream(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1], b: [2]}) |> Enum.to_list() |> Enum.sort()
      [{:a, [1, 2]}, {:b, [2, 3]}]

      iex> ExBags.difference_stream(%{}, %{a: [1]}) |> Enum.to_list()
      []

  """
  @spec difference_stream(map(), map()) :: Enumerable.t()
  def difference_stream(bag1, bag2) when is_map(bag1) and is_map(bag2) do
    bag1
    |> Stream.map(fn {key, values1} ->
      values2 = Map.get(bag2, key, [])
      difference_values = bag_difference(values1, values2)
      {key, difference_values}
    end)
    |> Stream.reject(fn {_key, values} -> Enum.empty?(values) end)
  end

  @doc """
  Returns a stream of key-value pairs that exist in either map but not in both.

  This is a memory-efficient version of `symmetric_difference/2` that returns a stream
  instead of a map. Useful for processing large maps without loading everything
  into memory.

  ## Examples

      iex> ExBags.symmetric_difference_stream(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]}) |> Enum.to_list() |> Enum.sort()
      [{:a, [1, 2]}, {:b, [3, 4]}, {:c, [5]}]

      iex> ExBags.symmetric_difference_stream(%{a: [1, 1, 2]}, %{a: [1, 2, 2]}) |> Enum.to_list() |> Enum.sort()
      [{:a, [1, 2]}]

      iex> ExBags.symmetric_difference_stream(%{a: [1, 2]}, %{c: [3, 4]}) |> Enum.to_list() |> Enum.sort()
      [{:a, [1, 2]}, {:c, [3, 4]}]

  """
  @spec symmetric_difference_stream(map(), map()) :: Enumerable.t()
  def symmetric_difference_stream(bag1, bag2) when is_map(bag1) and is_map(bag2) do
    keys1 = Map.keys(bag1)
    keys2 = Map.keys(bag2)

    only_in_bag1 = keys1 -- keys2
    only_in_bag2 = keys2 -- keys1
    common_keys = keys1 -- only_in_bag1

    # Keys only in bag1
    stream1 = Stream.map(only_in_bag1, fn key -> {key, Map.get(bag1, key)} end)

    # Keys only in bag2
    stream2 = Stream.map(only_in_bag2, fn key -> {key, Map.get(bag2, key)} end)

    # Common keys with symmetric difference of values
    stream3 = common_keys
    |> Stream.map(fn key ->
      values1 = Map.get(bag1, key, [])
      values2 = Map.get(bag2, key, [])
      sym_diff_values = bag_symmetric_difference(values1, values2)
      {key, sym_diff_values}
    end)
    |> Stream.reject(fn {_key, values} -> Enum.empty?(values) end)

    Stream.concat(Stream.concat(stream1, stream2), stream3)
  end

  @doc """
  Performs a reconciliation operation similar to SQL's FULL OUTER JOIN, returning streams.

  Returns a tuple of three streams:
  - First stream: key-value pairs that exist in both maps (intersection)
  - Second stream: key-value pairs that exist only in the first map
  - Third stream: key-value pairs that exist only in the second map

  This is a memory-efficient version of `reconcile/2` that returns streams
  instead of maps. Useful for processing large maps without loading everything
  into memory.

  ## Examples

      iex> {common, only_first, only_second} = ExBags.reconcile_stream(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
      iex> {Enum.to_list(common) |> Enum.sort(), Enum.to_list(only_first) |> Enum.sort(), Enum.to_list(only_second) |> Enum.sort()}
      {[{:b, [2]}], [{:a, [1, 2]}, {:b, [3]}], [{:b, [4]}, {:c, [5]}]}

      iex> {common, only_first, only_second} = ExBags.reconcile_stream(%{a: [1]}, %{b: [2]})
      iex> {Enum.to_list(common), Enum.to_list(only_first), Enum.to_list(only_second)}
      {[], [{:a, [1]}], [{:b, [2]}]}

      iex> {common, only_first, only_second} = ExBags.reconcile_stream(%{a: [1], b: [2]}, %{a: [1], b: [2]})
      iex> {Enum.to_list(common) |> Enum.sort(), Enum.to_list(only_first), Enum.to_list(only_second)}
      {[{:a, [1]}, {:b, [2]}], [], []}

  """
  @spec reconcile_stream(map(), map()) :: {Enumerable.t(), Enumerable.t(), Enumerable.t()}
  def reconcile_stream(map1, map2) when is_map(map1) and is_map(map2) do
    # For reconcile_stream, we want the actual intersection of values, not tuples
    common_stream = map1
    |> Map.keys()
    |> Stream.filter(&Map.has_key?(map2, &1))
    |> Stream.map(fn key ->
      values1 = Map.get(map1, key, [])
      values2 = Map.get(map2, key, [])
      intersection_values = bag_intersection(values1, values2)
      {key, intersection_values}
    end)
    |> Stream.reject(fn {_key, values} -> Enum.empty?(values) end)

    only_first_stream = difference_stream(map1, map2)
    only_second_stream = difference_stream(map2, map1)

    {common_stream, only_first_stream, only_second_stream}
  end
end
