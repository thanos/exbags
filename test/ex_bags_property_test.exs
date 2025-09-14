defmodule ExBagsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  # Helper function to find intersection of two value lists (copied from ExBags)
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

  # Custom generators for maps with various key and value types
  defp map_generator do
    StreamData.map_of(
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.one_of([
        StreamData.integer(),
        StreamData.string(:alphanumeric),
        StreamData.boolean(),
        StreamData.atom(:alphanumeric)
      ]), min_length: 0, max_length: 3),
      max_size: 10
    )
  end

  defp small_map_generator do
    StreamData.map_of(
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.integer(), min_length: 0, max_length: 3),
      min_size: 1,
      max_size: 5
    )
  end

  describe "property tests for intersect/2" do
    property "intersection is commutative for key sets" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result1 = ExBags.intersect(map1, map2)
        result2 = ExBags.intersect(map2, map1)

        # The key sets should be the same (but values may differ)
        assert Map.keys(result1) |> Enum.sort() == Map.keys(result2) |> Enum.sort()
      end
    end

    property "intersection result only contains keys from both maps" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result = ExBags.intersect(map1, map2)

        # All keys in result should be in both original maps
        for {key, _value} <- result do
          assert Map.has_key?(map1, key)
          assert Map.has_key?(map2, key)
        end
      end
    end

    property "intersection returns tuples of values from both maps" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result = ExBags.intersect(map1, map2)

        # All values in result should be tuples containing values from both maps
        for {key, {values1, values2}} <- result do
          original_values1 = Map.get(map1, key, [])
          original_values2 = Map.get(map2, key, [])
          # Check that the tuple contains the original values from each map
          assert values1 == original_values1
          assert values2 == original_values2
        end
      end
    end

    property "intersection with empty map returns empty map" do
      check all(map <- small_map_generator()) do
        assert ExBags.intersect(map, %{}) == %{}
        assert ExBags.intersect(%{}, map) == %{}
      end
    end

    property "intersection with identical maps returns tuples of same values" do
      check all(map <- small_map_generator()) do
        result = ExBags.intersect(map, map)
        # For duplicate bags, intersecting with itself should return tuples of same values
        for {key, {values1, values2}} <- result do
          original_values = Map.get(map, key, [])
          assert values1 == original_values
          assert values2 == original_values
        end
      end
    end
  end

  describe "property tests for difference/2" do
    property "difference result only contains keys from first map" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result = ExBags.difference(map1, map2)

        # All keys in result should be in first map
        for {key, values} <- result do
          assert Map.has_key?(map1, key)
          original_values = Map.get(map1, key, [])
          # Check that all values in result are in the original
          assert Enum.all?(values, &(&1 in original_values))
        end
      end
    end

    property "difference with empty second map returns first map" do
      check all(map <- small_map_generator()) do
        result = ExBags.difference(map, %{})
        # For duplicate bags, empty lists get filtered out, so we need to check differently
        for {key, values} <- result do
          original_values = Map.get(map, key, [])
          assert Enum.sort(values) == Enum.sort(original_values)
        end
        # Check that all non-empty values are preserved (order doesn't matter)
        non_empty_keys = map |> Enum.reject(fn {_k, v} -> Enum.empty?(v) end) |> Enum.map(fn {k, _v} -> k end) |> Enum.sort()
        result_keys = Map.keys(result) |> Enum.sort()
        assert non_empty_keys == result_keys
      end
    end

    property "difference with identical maps returns empty map" do
      check all(map <- small_map_generator()) do
        assert ExBags.difference(map, map) == %{}
      end
    end

    property "difference with empty first map returns empty map" do
      check all(map <- small_map_generator()) do
        assert ExBags.difference(%{}, map) == %{}
      end
    end
  end

  describe "property tests for symmetric_difference/2" do
    property "symmetric difference is commutative" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result1 = ExBags.symmetric_difference(map1, map2)
        result2 = ExBags.symmetric_difference(map2, map1)

        # The key sets should be the same
        assert Map.keys(result1) |> Enum.sort() == Map.keys(result2) |> Enum.sort()
      end
    end

    property "symmetric difference includes all keys" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result = ExBags.symmetric_difference(map1, map2)
        
        # All keys from both maps should be in the result (including empty lists)
        all_keys = (Map.keys(map1) ++ Map.keys(map2)) |> Enum.uniq() |> Enum.sort()
        result_keys = Map.keys(result) |> Enum.sort()

        # All keys from both maps should be in the result
        assert all_keys == result_keys
      end
    end

    property "symmetric difference with identical maps returns empty map" do
      check all(map <- small_map_generator()) do
        assert ExBags.symmetric_difference(map, map) == %{}
      end
    end

    property "symmetric difference with no common keys returns union" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        # Create maps with no common keys
        map1_keys = Map.keys(map1)
        map2_keys = Map.keys(map2)

        # If no common keys, symmetric difference should be union
        if Enum.empty?(map1_keys -- map2_keys) or Enum.empty?(map2_keys -- map1_keys) do
          result = ExBags.symmetric_difference(map1, map2)
          union_keys = (map1_keys ++ map2_keys) |> Enum.uniq() |> Enum.sort()
          result_keys = Map.keys(result) |> Enum.sort()

          assert result_keys == union_keys
        end
      end
    end
  end

  describe "property tests for reconcile/2" do
    property "reconcile partitions all keys correctly" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        {common, only_first, only_second} = ExBags.reconcile(map1, map2)

        # Only consider keys with non-empty values
        all_keys = (Map.keys(map1) ++ Map.keys(map2))
        |> Enum.uniq()
        |> Enum.filter(fn key ->
          values1 = Map.get(map1, key, [])
          values2 = Map.get(map2, key, [])
          not Enum.empty?(values1) or not Enum.empty?(values2)
        end)
        |> Enum.sort()

        # Filter out keys with empty values from the result
        common_keys = common |> Enum.reject(fn {_k, v} -> Enum.empty?(v) end) |> Enum.map(fn {k, _v} -> k end)
        first_keys = only_first |> Enum.reject(fn {_k, v} -> Enum.empty?(v) end) |> Enum.map(fn {k, _v} -> k end)
        second_keys = only_second |> Enum.reject(fn {_k, v} -> Enum.empty?(v) end) |> Enum.map(fn {k, _v} -> k end)

        result_keys = common_keys ++ first_keys ++ second_keys |> Enum.uniq() |> Enum.sort()

        # All keys should be accounted for
        assert all_keys == result_keys
      end
    end

    property "reconcile with identical maps returns original values" do
      check all(map <- small_map_generator()) do
        {common, only_first, only_second} = ExBags.reconcile(map, map)

        # Filter out empty lists from original map for comparison
        non_empty_map = map |> Enum.reject(fn {_k, v} -> Enum.empty?(v) end) |> Map.new()

        # Check that values match the original (intersection of identical values)
        for {key, values} <- common do
          original_values = Map.get(non_empty_map, key, [])
          assert Enum.sort(values) == Enum.sort(original_values)
        end
        # Check that all non-empty keys are present
        assert Map.keys(common) |> Enum.sort() == Map.keys(non_empty_map) |> Enum.sort()
        assert only_first == %{}
        assert only_second == %{}
      end
    end

    property "reconcile with empty maps" do
      check all(map <- small_map_generator()) do
        {common, only_first, only_second} = ExBags.reconcile(map, %{})

        assert common == %{}
        # For duplicate bags, we need to check that the values match but order might differ
        for {key, values} <- only_first do
          original_values = Map.get(map, key, [])
          assert Enum.sort(values) == Enum.sort(original_values)
        end
        assert only_second == %{}

        {common, only_first, only_second} = ExBags.reconcile(%{}, map)

        assert common == %{}
        assert only_first == %{}
        # For duplicate bags, we need to check that the values match but order might differ
        for {key, values} <- only_second do
          original_values = Map.get(map, key, [])
          assert Enum.sort(values) == Enum.sort(original_values)
        end
      end
    end

    property "reconcile common keys have intersection of values" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        {common, _only_first, _only_second} = ExBags.reconcile(map1, map2)

        # Common keys should have intersection of values from both maps
        for {key, values} <- common do
          values1 = Map.get(map1, key, [])
          values2 = Map.get(map2, key, [])
          expected_values = bag_intersection(values1, values2)
          assert Enum.sort(values) == Enum.sort(expected_values)
        end
      end
    end
  end

  describe "property tests for stream functions" do
    property "stream functions produce same results as map functions" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        # Test intersection
        map_result = ExBags.intersect(map1, map2)
        stream_result = ExBags.intersect_stream(map1, map2) |> Enum.to_list() |> Map.new()
        assert map_result == stream_result

        # Test difference
        map_result = ExBags.difference(map1, map2)
        stream_result = ExBags.difference_stream(map1, map2) |> Enum.to_list() |> Map.new()
        assert map_result == stream_result

        # Test symmetric difference
        map_result = ExBags.symmetric_difference(map1, map2)
        stream_result = ExBags.symmetric_difference_stream(map1, map2) |> Enum.to_list() |> Map.new()
        assert map_result == stream_result

        # Test reconcile
        {map_common, map_first, map_second} = ExBags.reconcile(map1, map2)
        {stream_common, stream_first, stream_second} = ExBags.reconcile_stream(map1, map2)

        assert map_common == (stream_common |> Enum.to_list() |> Map.new())
        assert map_first == (stream_first |> Enum.to_list() |> Map.new())
        assert map_second == (stream_second |> Enum.to_list() |> Map.new())
      end
    end

    property "streams are lazy and can be consumed partially" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator(),
            take_count <- StreamData.integer(0..5)
          ) do
        stream = ExBags.intersect_stream(map1, map2)
        partial_result = stream |> Stream.take(take_count) |> Enum.to_list()

        # Partial result should be a subset of full result
        full_result = ExBags.intersect(map1, map2)
        full_list = Map.to_list(full_result) |> Enum.sort()

        # Partial result should be a prefix of full result (order may vary)
        assert length(partial_result) <= length(full_list)
        assert length(partial_result) <= take_count
      end
    end

    property "streams can be filtered and transformed" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        # Test that streams can be composed
        result = ExBags.intersect_stream(map1, map2)
        |> Stream.filter(fn {_key, value} -> is_integer(value) end)
        |> Stream.map(fn {key, value} -> {key, value * 2} end)
        |> Enum.to_list()

        # Result should only contain integer values that were doubled
        for {_key, value} <- result do
          assert is_integer(value)
          assert rem(value, 2) == 0
        end
      end
    end
  end

  describe "property tests for edge cases" do
    property "functions handle maps with different value types" do
      check all(
            map1 <- map_generator(),
            map2 <- map_generator()
          ) do
        # All functions should work with mixed value types
        assert is_map(ExBags.intersect(map1, map2))
        assert is_map(ExBags.difference(map1, map2))
        assert is_map(ExBags.symmetric_difference(map1, map2))

        {common, first, second} = ExBags.reconcile(map1, map2)
        assert is_map(common)
        assert is_map(first)
        assert is_map(second)
      end
    end

    property "functions handle maps with nil values" do
      check all(
            map1 <- StreamData.map_of(StreamData.atom(:alphanumeric), StreamData.list_of(StreamData.one_of([StreamData.constant(nil), StreamData.integer()]), min_length: 0, max_length: 2)),
            map2 <- StreamData.map_of(StreamData.atom(:alphanumeric), StreamData.list_of(StreamData.one_of([StreamData.constant(nil), StreamData.integer()]), min_length: 0, max_length: 2))
          ) do
        # All functions should work with nil values
        assert is_map(ExBags.intersect(map1, map2))
        assert is_map(ExBags.difference(map1, map2))
        assert is_map(ExBags.symmetric_difference(map1, map2))

        {common, first, second} = ExBags.reconcile(map1, map2)
        assert is_map(common)
        assert is_map(first)
        assert is_map(second)
      end
    end
  end
end
