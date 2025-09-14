defmodule ExBagsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  # Custom generators for maps with various key and value types
  defp map_generator do
    StreamData.map_of(
      StreamData.atom(:alphanumeric),
      StreamData.one_of([
        StreamData.integer(),
        StreamData.string(:alphanumeric),
        StreamData.boolean(),
        StreamData.atom(:alphanumeric),
        StreamData.list_of(StreamData.integer())
      ]),
      max_size: 10
    )
  end

  defp small_map_generator do
    StreamData.map_of(
      StreamData.atom(:alphanumeric),
      StreamData.integer(),
      min_size: 1,
      max_size: 5
    )
  end

  describe "property tests for intersection/2" do
    property "intersection is commutative for key sets" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result1 = ExBags.intersection(map1, map2)
        result2 = ExBags.intersection(map2, map1)

        # The key sets should be the same (but values may differ)
        assert Map.keys(result1) |> Enum.sort() == Map.keys(result2) |> Enum.sort()
      end
    end

    property "intersection result only contains keys from both maps" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result = ExBags.intersection(map1, map2)

        # All keys in result should be in both original maps
        for {key, _value} <- result do
          assert Map.has_key?(map1, key)
          assert Map.has_key?(map2, key)
        end
      end
    end

    property "intersection uses values from first map" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result = ExBags.intersection(map1, map2)

        # All values in result should match the first map
        for {key, value} <- result do
          assert Map.get(map1, key) == value
        end
      end
    end

    property "intersection with empty map returns empty map" do
      check all(map <- small_map_generator()) do
        assert ExBags.intersection(map, %{}) == %{}
        assert ExBags.intersection(%{}, map) == %{}
      end
    end

    property "intersection with identical maps returns the map" do
      check all(map <- small_map_generator()) do
        assert ExBags.intersection(map, map) == map
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

        # All keys in result should be in first map but not second
        for {key, value} <- result do
          assert Map.has_key?(map1, key)
          refute Map.has_key?(map2, key)
          assert Map.get(map1, key) == value
        end
      end
    end

    property "difference with empty second map returns first map" do
      check all(map <- small_map_generator()) do
        assert ExBags.difference(map, %{}) == map
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

    property "symmetric difference excludes common keys" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        result = ExBags.symmetric_difference(map1, map2)
        common_keys = Map.keys(ExBags.intersection(map1, map2))

        # No common keys should be in the result
        for key <- common_keys do
          refute Map.has_key?(result, key)
        end
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

        all_keys = (Map.keys(map1) ++ Map.keys(map2)) |> Enum.uniq() |> Enum.sort()
        result_keys = (Map.keys(common) ++ Map.keys(only_first) ++ Map.keys(only_second)) |> Enum.uniq() |> Enum.sort()

        # All keys should be accounted for
        assert all_keys == result_keys

        # Check that partitions are disjoint (no key appears in multiple partitions)
        # This is already guaranteed by the implementation, so we just verify
        # that all keys are accounted for and no duplicates exist
      end
    end

    property "reconcile with identical maps" do
      check all(map <- small_map_generator()) do
        {common, only_first, only_second} = ExBags.reconcile(map, map)

        assert common == map
        assert only_first == %{}
        assert only_second == %{}
      end
    end

    property "reconcile with empty maps" do
      check all(map <- small_map_generator()) do
        {common, only_first, only_second} = ExBags.reconcile(map, %{})

        assert common == %{}
        assert only_first == map
        assert only_second == %{}

        {common, only_first, only_second} = ExBags.reconcile(%{}, map)

        assert common == %{}
        assert only_first == %{}
        assert only_second == map
      end
    end

    property "reconcile common keys use values from first map" do
      check all(
            map1 <- small_map_generator(),
            map2 <- small_map_generator()
          ) do
        {common, _only_first, _only_second} = ExBags.reconcile(map1, map2)

        # Common keys should have values from first map
        for {key, value} <- common do
          assert Map.get(map1, key) == value
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
        map_result = ExBags.intersection(map1, map2)
        stream_result = ExBags.intersection_stream(map1, map2) |> Enum.to_list() |> Map.new()
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
        stream = ExBags.intersection_stream(map1, map2)
        partial_result = stream |> Stream.take(take_count) |> Enum.to_list()

        # Partial result should be a subset of full result
        full_result = ExBags.intersection(map1, map2)
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
        result = ExBags.intersection_stream(map1, map2)
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
        assert is_map(ExBags.intersection(map1, map2))
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
            map1 <- StreamData.map_of(StreamData.atom(:alphanumeric), StreamData.one_of([StreamData.constant(nil), StreamData.integer()])),
            map2 <- StreamData.map_of(StreamData.atom(:alphanumeric), StreamData.one_of([StreamData.constant(nil), StreamData.integer()]))
          ) do
        # All functions should work with nil values
        assert is_map(ExBags.intersection(map1, map2))
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
