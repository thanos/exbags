defmodule ExBags do
  @moduledoc """
  ExBags provides a duplicate bag (multiset) implementation for Elixir that allows
  multiple values for the same key, along with set-like operations including
  intersect, difference, symmetric difference, and reconciliation.

  A duplicate bag is like a map but allows multiple values for the same key.
  Internally, it stores values as lists, and provides operations to work with
  these multisets efficiently.

  ## Examples

      iex> bag = ExBags.new()
      iex> bag = ExBags.put(bag, :a, 1)
      iex> bag = ExBags.put(bag, :a, 2)
      iex> ExBags.get(bag, :a)
      [1, 2]

      iex> ExBags.intersect(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
      %{b: [2]}

      iex> ExBags.difference(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
      %{a: [1, 2], b: [3]}

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

  For duplicate bags, this finds the intersection of values for each common key.
  The result contains the minimum count of each value that appears in both bags.

  ## Examples

      iex> ExBags.intersect(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
      %{b: [2]}

      iex> ExBags.intersect(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1, 2], b: [2, 4]})
      %{a: [1, 2], b: [2]}

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
      intersection_values = bag_intersection(values1, values2)
      {key, intersection_values}
    end)
    |> Enum.reject(fn {_key, values} -> Enum.empty?(values) end)
    |> Map.new()
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
    intersection = intersect(bag1, bag2)
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
      [{:b, [2]}]

      iex> ExBags.intersect_stream(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1, 2], b: [2, 4]}) |> Enum.to_list() |> Enum.sort()
      [{:a, [1, 2]}, {:b, [2]}]

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
      intersection_values = bag_intersection(values1, values2)
      {key, intersection_values}
    end)
    |> Stream.reject(fn {_key, values} -> Enum.empty?(values) end)
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
    common_stream = intersect_stream(map1, map2)
    only_first_stream = difference_stream(map1, map2)
    only_second_stream = difference_stream(map2, map1)

    {common_stream, only_first_stream, only_second_stream}
  end
end
