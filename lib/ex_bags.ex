defmodule ExBags do
  @moduledoc """
  ExBags provides enhanced map operations that extend Elixir's built-in Map module
  with set-like operations including intersection, difference, symmetric difference,
  and reconciliation (full outer join).

  ## Examples

      iex> ExBags.intersection(%{a: 1, b: 2}, %{b: 2, c: 3})
      %{b: 2}

      iex> ExBags.difference(%{a: 1, b: 2}, %{b: 2, c: 3})
      %{a: 1}

      iex> ExBags.symmetric_difference(%{a: 1, b: 2}, %{b: 2, c: 3})
      %{a: 1, c: 3}

      iex> ExBags.reconcile(%{a: 1, b: 2}, %{b: 2, c: 3})
      {%{b: 2}, %{a: 1}, %{c: 3}}

  """

  @doc """
  Returns a map containing only the key-value pairs that exist in both maps.

  If a key exists in both maps but with different values, the value from the first map is used.

  ## Examples

      iex> ExBags.intersection(%{a: 1, b: 2}, %{b: 2, c: 3})
      %{b: 2}

      iex> ExBags.intersection(%{a: 1, b: 2}, %{b: 3, c: 4})
      %{b: 2}

      iex> ExBags.intersection(%{}, %{a: 1})
      %{}

  """
  @spec intersection(map(), map()) :: map()
  def intersection(map1, map2) when is_map(map1) and is_map(map2) do
    map1
    |> Map.keys()
    |> Enum.filter(&Map.has_key?(map2, &1))
    |> Enum.into(%{}, fn key -> {key, Map.get(map1, key)} end)
  end

  @doc """
  Returns a map containing only the key-value pairs that exist in the first map
  but not in the second map.

  ## Examples

      iex> ExBags.difference(%{a: 1, b: 2}, %{b: 2, c: 3})
      %{a: 1}

      iex> ExBags.difference(%{a: 1, b: 2}, %{a: 1, b: 2})
      %{}

      iex> ExBags.difference(%{}, %{a: 1})
      %{}

  """
  @spec difference(map(), map()) :: map()
  def difference(map1, map2) when is_map(map1) and is_map(map2) do
    map1
    |> Map.keys()
    |> Enum.reject(&Map.has_key?(map2, &1))
    |> Enum.into(%{}, fn key -> {key, Map.get(map1, key)} end)
  end

  @doc """
  Returns a map containing key-value pairs that exist in either map but not in both.

  If a key exists in both maps, it is excluded from the result.

  ## Examples

      iex> ExBags.symmetric_difference(%{a: 1, b: 2}, %{b: 2, c: 3})
      %{a: 1, c: 3}

      iex> ExBags.symmetric_difference(%{a: 1}, %{a: 1})
      %{}

      iex> ExBags.symmetric_difference(%{a: 1, b: 2}, %{c: 3, d: 4})
      %{a: 1, b: 2, c: 3, d: 4}

  """
  @spec symmetric_difference(map(), map()) :: map()
  def symmetric_difference(map1, map2) when is_map(map1) and is_map(map2) do
    keys1 = Map.keys(map1)
    keys2 = Map.keys(map2)

    only_in_map1 = keys1 -- keys2
    only_in_map2 = keys2 -- keys1

    result1 = Enum.into(only_in_map1, %{}, fn key -> {key, Map.get(map1, key)} end)
    result2 = Enum.into(only_in_map2, %{}, fn key -> {key, Map.get(map2, key)} end)

    Map.merge(result1, result2)
  end

  @doc """
  Performs a reconciliation operation similar to SQL's FULL OUTER JOIN.

  Returns a tuple of three maps:
  - First map: key-value pairs that exist in both maps (intersection)
  - Second map: key-value pairs that exist only in the first map
  - Third map: key-value pairs that exist only in the second map

  ## Examples

      iex> ExBags.reconcile(%{a: 1, b: 2}, %{b: 2, c: 3})
      {%{b: 2}, %{a: 1}, %{c: 3}}

      iex> ExBags.reconcile(%{a: 1}, %{b: 2})
      {%{}, %{a: 1}, %{b: 2}}

      iex> ExBags.reconcile(%{a: 1, b: 2}, %{a: 1, b: 2})
      {%{a: 1, b: 2}, %{}, %{}}

  """
  @spec reconcile(map(), map()) :: {map(), map(), map()}
  def reconcile(map1, map2) when is_map(map1) and is_map(map2) do
    intersection = intersection(map1, map2)
    only_in_map1 = difference(map1, map2)
    only_in_map2 = difference(map2, map1)

    {intersection, only_in_map1, only_in_map2}
  end

  @doc """
  Returns a stream of key-value pairs that exist in both maps.

  This is a memory-efficient version of `intersection/2` that returns a stream
  instead of a map. Useful for processing large maps without loading everything
  into memory.

  ## Examples

      iex> ExBags.intersection_stream(%{a: 1, b: 2}, %{b: 2, c: 3}) |> Enum.to_list()
      [{:b, 2}]

      iex> ExBags.intersection_stream(%{a: 1, b: 2}, %{b: 3, c: 4}) |> Enum.to_list()
      [{:b, 2}]

      iex> ExBags.intersection_stream(%{}, %{a: 1}) |> Enum.to_list()
      []

  """
  @spec intersection_stream(map(), map()) :: Enumerable.t()
  def intersection_stream(map1, map2) when is_map(map1) and is_map(map2) do
    map1
    |> Map.keys()
    |> Stream.filter(&Map.has_key?(map2, &1))
    |> Stream.map(fn key -> {key, Map.get(map1, key)} end)
  end

  @doc """
  Returns a stream of key-value pairs that exist in the first map but not in the second map.

  This is a memory-efficient version of `difference/2` that returns a stream
  instead of a map. Useful for processing large maps without loading everything
  into memory.

  ## Examples

      iex> ExBags.difference_stream(%{a: 1, b: 2}, %{b: 2, c: 3}) |> Enum.to_list()
      [{:a, 1}]

      iex> ExBags.difference_stream(%{a: 1, b: 2}, %{a: 1, b: 2}) |> Enum.to_list()
      []

      iex> ExBags.difference_stream(%{}, %{a: 1}) |> Enum.to_list()
      []

  """
  @spec difference_stream(map(), map()) :: Enumerable.t()
  def difference_stream(map1, map2) when is_map(map1) and is_map(map2) do
    map1
    |> Map.keys()
    |> Stream.reject(&Map.has_key?(map2, &1))
    |> Stream.map(fn key -> {key, Map.get(map1, key)} end)
  end

  @doc """
  Returns a stream of key-value pairs that exist in either map but not in both.

  This is a memory-efficient version of `symmetric_difference/2` that returns a stream
  instead of a map. Useful for processing large maps without loading everything
  into memory.

  ## Examples

      iex> ExBags.symmetric_difference_stream(%{a: 1, b: 2}, %{b: 2, c: 3}) |> Enum.to_list()
      [{:a, 1}, {:c, 3}]

      iex> ExBags.symmetric_difference_stream(%{a: 1}, %{a: 1}) |> Enum.to_list()
      []

      iex> ExBags.symmetric_difference_stream(%{a: 1, b: 2}, %{c: 3, d: 4}) |> Enum.to_list() |> Enum.sort()
      [{:a, 1}, {:b, 2}, {:c, 3}, {:d, 4}]

  """
  @spec symmetric_difference_stream(map(), map()) :: Enumerable.t()
  def symmetric_difference_stream(map1, map2) when is_map(map1) and is_map(map2) do
    keys1 = Map.keys(map1)
    keys2 = Map.keys(map2)

    only_in_map1 = keys1 -- keys2
    only_in_map2 = keys2 -- keys1

    stream1 = Stream.map(only_in_map1, fn key -> {key, Map.get(map1, key)} end)
    stream2 = Stream.map(only_in_map2, fn key -> {key, Map.get(map2, key)} end)

    Stream.concat(stream1, stream2)
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

      iex> {common, only_first, only_second} = ExBags.reconcile_stream(%{a: 1, b: 2}, %{b: 2, c: 3})
      iex> {Enum.to_list(common), Enum.to_list(only_first), Enum.to_list(only_second)}
      {[{:b, 2}], [{:a, 1}], [{:c, 3}]}

      iex> {common, only_first, only_second} = ExBags.reconcile_stream(%{a: 1}, %{b: 2})
      iex> {Enum.to_list(common), Enum.to_list(only_first), Enum.to_list(only_second)}
      {[], [{:a, 1}], [{:b, 2}]}

      iex> {common, only_first, only_second} = ExBags.reconcile_stream(%{a: 1, b: 2}, %{a: 1, b: 2})
      iex> {Enum.to_list(common) |> Enum.sort(), Enum.to_list(only_first), Enum.to_list(only_second)}
      {[{:a, 1}, {:b, 2}], [], []}

  """
  @spec reconcile_stream(map(), map()) :: {Enumerable.t(), Enumerable.t(), Enumerable.t()}
  def reconcile_stream(map1, map2) when is_map(map1) and is_map(map2) do
    common_stream = intersection_stream(map1, map2)
    only_first_stream = difference_stream(map1, map2)
    only_second_stream = difference_stream(map2, map1)

    {common_stream, only_first_stream, only_second_stream}
  end
end
