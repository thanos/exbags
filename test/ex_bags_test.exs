defmodule ExBagsTest do
  use ExUnit.Case
  doctest ExBags

  describe "new/0" do
    test "creates empty bag" do
      assert ExBags.new() == %{}
    end
  end

  describe "put/3" do
    test "adds value to new key" do
      bag = ExBags.new()
      bag = ExBags.put(bag, :a, 1)
      assert bag == %{a: [1]}
    end

    test "adds value to existing key" do
      bag = %{a: [1]}
      bag = ExBags.put(bag, :a, 2)
      assert bag == %{a: [1, 2]}
    end

    test "adds multiple values to same key" do
      bag = ExBags.new()
      bag = ExBags.put(bag, :a, 1)
      bag = ExBags.put(bag, :a, 2)
      bag = ExBags.put(bag, :a, 3)
      assert bag == %{a: [1, 2, 3]}
    end
  end

  describe "get/2" do
    test "returns values for existing key" do
      bag = %{a: [1, 2, 3]}
      assert ExBags.get(bag, :a) == [1, 2, 3]
    end

    test "returns empty list for non-existing key" do
      bag = %{a: [1, 2]}
      assert ExBags.get(bag, :b) == []
    end
  end

  describe "keys/1" do
    test "returns all keys" do
      bag = %{a: [1], b: [2], c: [3]}
      keys = ExBags.keys(bag)
      assert :a in keys
      assert :b in keys
      assert :c in keys
      assert length(keys) == 3
    end
  end

  describe "values/1" do
    test "returns all values flattened" do
      bag = %{a: [1, 2], b: [3, 4]}
      values = ExBags.values(bag)
      assert Enum.sort(values) == [1, 2, 3, 4]
    end
  end

  describe "update/3" do
    test "updates values for existing key" do
      bag = %{a: [1, 2, 3]}
      bag = ExBags.update(bag, :a, fn values -> Enum.map(values, &(&1 * 2)) end)
      assert bag == %{a: [2, 4, 6]}
    end

    test "updates values for non-existing key" do
      bag = %{}
      bag = ExBags.update(bag, :a, fn values -> values ++ [10] end)
      assert bag == %{a: [10]}
    end
  end

  describe "intersect/2" do
    test "merges values for common keys" do
      bag1 = %{a: [1, 2], b: [2, 3]}
      bag2 = %{b: [2, 4], c: [5]}

      result = ExBags.intersect(bag1, bag2)
      expected = %{b: [2, 3, 2, 4]}

      assert result == expected
    end

    test "returns empty bag when no common keys" do
      bag1 = %{a: [1], b: [2]}
      bag2 = %{c: [3], d: [4]}

      result = ExBags.intersect(bag1, bag2)

      assert result == %{}
    end

    test "returns empty bag when first bag is empty" do
      bag1 = %{}
      bag2 = %{a: [1], b: [2]}

      result = ExBags.intersect(bag1, bag2)

      assert result == %{}
    end

    test "returns empty bag when second bag is empty" do
      bag1 = %{a: [1], b: [2]}
      bag2 = %{}

      result = ExBags.intersect(bag1, bag2)

      assert result == %{}
    end

    test "returns all pairs when bags are identical" do
      bag1 = %{a: [1], b: [2]}
      bag2 = %{a: [1], b: [2]}

      result = ExBags.intersect(bag1, bag2)

      assert result == %{a: [1, 1], b: [2, 2]}
    end

    test "handles duplicate values correctly" do
      bag1 = %{a: [1, 1, 2], b: [2, 2, 3]}
      bag2 = %{a: [1, 2], b: [2, 4]}

      result = ExBags.intersect(bag1, bag2)

      # Should merge all values from both bags
      assert Map.get(result, :a) |> Enum.sort() == [1, 1, 1, 2, 2]
      assert Map.get(result, :b) |> Enum.sort() == [2, 2, 2, 3, 4]
    end
  end

  describe "difference/2" do
    test "returns values only in first bag" do
      bag1 = %{a: [1, 2], b: [2, 3]}
      bag2 = %{b: [2, 4], c: [5]}

      result = ExBags.difference(bag1, bag2)
      expected = %{a: [1, 2], b: [3]}

      assert result == expected
    end

    test "returns empty bag when first bag is empty" do
      bag1 = %{}
      bag2 = %{a: [1], b: [2]}

      result = ExBags.difference(bag1, bag2)

      assert result == %{}
    end

    test "returns first bag when second bag is empty" do
      bag1 = %{a: [1], b: [2]}
      bag2 = %{}

      result = ExBags.difference(bag1, bag2)

      assert result == %{a: [1], b: [2]}
    end

    test "returns empty bag when bags are identical" do
      bag1 = %{a: [1], b: [2]}
      bag2 = %{a: [1], b: [2]}

      result = ExBags.difference(bag1, bag2)

      assert result == %{}
    end

    test "handles duplicate values correctly" do
      bag1 = %{a: [1, 1, 2], b: [2, 2, 3]}
      bag2 = %{a: [1], b: [2]}

      result = ExBags.difference(bag1, bag2)

      # Should subtract the counts
      assert Map.get(result, :a) |> Enum.sort() == [1, 2]
      assert Map.get(result, :b) |> Enum.sort() == [2, 3]
    end
  end

  describe "symmetric_difference/2" do
    test "returns values in either bag but not both" do
      bag1 = %{a: [1, 2], b: [2, 3]}
      bag2 = %{b: [2, 4], c: [5]}

      result = ExBags.symmetric_difference(bag1, bag2)

      # Should have values that differ in count
      assert Map.get(result, :a) |> Enum.sort() == [1, 2]
      assert Map.get(result, :b) |> Enum.sort() == [3, 4]
      assert Map.get(result, :c) |> Enum.sort() == [5]
    end

    test "returns empty bag when bags are identical" do
      bag1 = %{a: [1], b: [2]}
      bag2 = %{a: [1], b: [2]}

      result = ExBags.symmetric_difference(bag1, bag2)

      assert result == %{}
    end

    test "returns union when no common keys" do
      bag1 = %{a: [1], b: [2]}
      bag2 = %{c: [3], d: [4]}

      result = ExBags.symmetric_difference(bag1, bag2)

      assert Map.get(result, :a) == [1]
      assert Map.get(result, :b) == [2]
      assert Map.get(result, :c) == [3]
      assert Map.get(result, :d) == [4]
    end

    test "handles duplicate values correctly" do
      bag1 = %{a: [1, 1, 2]}
      bag2 = %{a: [1, 2, 2]}

      result = ExBags.symmetric_difference(bag1, bag2)

      # Should have the difference in counts
      assert Map.get(result, :a) |> Enum.sort() == [1, 2]
    end
  end

  describe "reconcile/2" do
    test "returns three bags: common, only first, only second" do
      bag1 = %{a: [1, 2], b: [2, 3]}
      bag2 = %{b: [2, 4], c: [5]}

      {common, only_first, only_second} = ExBags.reconcile(bag1, bag2)

      assert common == %{b: [2, 3, 2, 4]}
      assert only_first == %{a: [1, 2], b: [3]}
      assert only_second == %{b: [4], c: [5]}
    end

    test "handles empty bags" do
      {common, only_first, only_second} = ExBags.reconcile(%{}, %{})

      assert common == %{}
      assert only_first == %{}
      assert only_second == %{}
    end

    test "handles one empty bag" do
      bag1 = %{a: [1], b: [2]}
      bag2 = %{}

      {common, only_first, only_second} = ExBags.reconcile(bag1, bag2)

      assert common == %{}
      assert only_first == %{a: [1], b: [2]}
      assert only_second == %{}
    end

    test "handles identical bags" do
      bag1 = %{a: [1], b: [2]}
      bag2 = %{a: [1], b: [2]}

      {common, only_first, only_second} = ExBags.reconcile(bag1, bag2)

      assert common == %{a: [1, 1], b: [2, 2]}
      assert only_first == %{}
      assert only_second == %{}
    end
  end

  describe "stream functions" do
    test "intersect_stream returns same result as intersect" do
      bag1 = %{a: [1, 2], b: [2, 3]}
      bag2 = %{b: [2, 4], c: [5]}

      result = ExBags.intersect(bag1, bag2)
      stream_result = ExBags.intersect_stream(bag1, bag2) |> Enum.to_list() |> Enum.sort()

      assert Map.to_list(result) |> Enum.sort() == stream_result
    end

    test "difference_stream returns same result as difference" do
      bag1 = %{a: [1, 2], b: [2, 3]}
      bag2 = %{b: [2, 4], c: [5]}

      result = ExBags.difference(bag1, bag2)
      stream_result = ExBags.difference_stream(bag1, bag2) |> Enum.to_list() |> Enum.sort()

      assert Map.to_list(result) |> Enum.sort() == stream_result
    end

    test "symmetric_difference_stream returns same result as symmetric_difference" do
      bag1 = %{a: [1, 2], b: [2, 3]}
      bag2 = %{b: [2, 4], c: [5]}

      result = ExBags.symmetric_difference(bag1, bag2)
      stream_result = ExBags.symmetric_difference_stream(bag1, bag2) |> Enum.to_list() |> Enum.sort()

      assert Map.to_list(result) |> Enum.sort() == stream_result
    end

    test "reconcile_stream returns same result as reconcile" do
      bag1 = %{a: [1, 2], b: [2, 3]}
      bag2 = %{b: [2, 4], c: [5]}

      {common, only_first, only_second} = ExBags.reconcile(bag1, bag2)
      {stream_common, stream_only_first, stream_only_second} = ExBags.reconcile_stream(bag1, bag2)

      assert Map.to_list(common) |> Enum.sort() == Enum.to_list(stream_common) |> Enum.sort()
      assert Map.to_list(only_first) |> Enum.sort() == Enum.to_list(stream_only_first) |> Enum.sort()
      assert Map.to_list(only_second) |> Enum.sort() == Enum.to_list(stream_only_second) |> Enum.sort()
    end
  end
end
