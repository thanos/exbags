defmodule ExBagsTest do
  use ExUnit.Case
  doctest ExBags

  describe "intersection/2" do
    test "returns common key-value pairs" do
      map1 = %{a: 1, b: 2, c: 3}
      map2 = %{b: 2, c: 4, d: 5}

      result = ExBags.intersection(map1, map2)
      expected = %{b: 2, c: 3}

      assert result == expected
    end

    test "returns empty map when no common keys" do
      map1 = %{a: 1, b: 2}
      map2 = %{c: 3, d: 4}

      result = ExBags.intersection(map1, map2)

      assert result == %{}
    end

    test "returns empty map when first map is empty" do
      map1 = %{}
      map2 = %{a: 1, b: 2}

      result = ExBags.intersection(map1, map2)

      assert result == %{}
    end

    test "returns empty map when second map is empty" do
      map1 = %{a: 1, b: 2}
      map2 = %{}

      result = ExBags.intersection(map1, map2)

      assert result == %{}
    end

    test "returns all pairs when maps are identical" do
      map1 = %{a: 1, b: 2}
      map2 = %{a: 1, b: 2}

      result = ExBags.intersection(map1, map2)

      assert result == %{a: 1, b: 2}
    end

    test "uses value from first map when keys match but values differ" do
      map1 = %{a: 1, b: 2}
      map2 = %{a: 10, b: 20}

      result = ExBags.intersection(map1, map2)

      assert result == %{a: 1, b: 2}
    end
  end

  describe "difference/2" do
    test "returns keys only in first map" do
      map1 = %{a: 1, b: 2, c: 3}
      map2 = %{b: 2, c: 4, d: 5}

      result = ExBags.difference(map1, map2)
      expected = %{a: 1}

      assert result == expected
    end

    test "returns all pairs when no common keys" do
      map1 = %{a: 1, b: 2}
      map2 = %{c: 3, d: 4}

      result = ExBags.difference(map1, map2)

      assert result == %{a: 1, b: 2}
    end

    test "returns empty map when first map is empty" do
      map1 = %{}
      map2 = %{a: 1, b: 2}

      result = ExBags.difference(map1, map2)

      assert result == %{}
    end

    test "returns all pairs when second map is empty" do
      map1 = %{a: 1, b: 2}
      map2 = %{}

      result = ExBags.difference(map1, map2)

      assert result == %{a: 1, b: 2}
    end

    test "returns empty map when maps are identical" do
      map1 = %{a: 1, b: 2}
      map2 = %{a: 1, b: 2}

      result = ExBags.difference(map1, map2)

      assert result == %{}
    end
  end

  describe "symmetric_difference/2" do
    test "returns keys in either map but not both" do
      map1 = %{a: 1, b: 2, c: 3}
      map2 = %{b: 2, c: 4, d: 5}

      result = ExBags.symmetric_difference(map1, map2)
      expected = %{a: 1, d: 5}

      assert result == expected
    end

    test "returns all pairs when no common keys" do
      map1 = %{a: 1, b: 2}
      map2 = %{c: 3, d: 4}

      result = ExBags.symmetric_difference(map1, map2)

      assert result == %{a: 1, b: 2, c: 3, d: 4}
    end

    test "returns all pairs from first map when second map is empty" do
      map1 = %{a: 1, b: 2}
      map2 = %{}

      result = ExBags.symmetric_difference(map1, map2)

      assert result == %{a: 1, b: 2}
    end

    test "returns all pairs from second map when first map is empty" do
      map1 = %{}
      map2 = %{a: 1, b: 2}

      result = ExBags.symmetric_difference(map1, map2)

      assert result == %{a: 1, b: 2}
    end

    test "returns empty map when maps are identical" do
      map1 = %{a: 1, b: 2}
      map2 = %{a: 1, b: 2}

      result = ExBags.symmetric_difference(map1, map2)

      assert result == %{}
    end

    test "excludes keys that exist in both maps regardless of values" do
      map1 = %{a: 1, b: 2}
      map2 = %{a: 10, b: 20}

      result = ExBags.symmetric_difference(map1, map2)

      assert result == %{}
    end
  end

  describe "reconcile/2" do
    test "returns three maps: intersection, only in first, only in second" do
      map1 = %{a: 1, b: 2, c: 3}
      map2 = %{b: 2, c: 4, d: 5}

      {intersection, only_in_first, only_in_second} = ExBags.reconcile(map1, map2)

      assert intersection == %{b: 2, c: 3}
      assert only_in_first == %{a: 1}
      assert only_in_second == %{d: 5}
    end

    test "returns empty intersection when no common keys" do
      map1 = %{a: 1, b: 2}
      map2 = %{c: 3, d: 4}

      {intersection, only_in_first, only_in_second} = ExBags.reconcile(map1, map2)

      assert intersection == %{}
      assert only_in_first == %{a: 1, b: 2}
      assert only_in_second == %{c: 3, d: 4}
    end

    test "returns all in intersection when maps are identical" do
      map1 = %{a: 1, b: 2}
      map2 = %{a: 1, b: 2}

      {intersection, only_in_first, only_in_second} = ExBags.reconcile(map1, map2)

      assert intersection == %{a: 1, b: 2}
      assert only_in_first == %{}
      assert only_in_second == %{}
    end

    test "handles empty maps correctly" do
      map1 = %{}
      map2 = %{a: 1, b: 2}

      {intersection, only_in_first, only_in_second} = ExBags.reconcile(map1, map2)

      assert intersection == %{}
      assert only_in_first == %{}
      assert only_in_second == %{a: 1, b: 2}
    end

    test "handles both empty maps" do
      map1 = %{}
      map2 = %{}

      {intersection, only_in_first, only_in_second} = ExBags.reconcile(map1, map2)

      assert intersection == %{}
      assert only_in_first == %{}
      assert only_in_second == %{}
    end

    test "uses value from first map in intersection when keys match but values differ" do
      map1 = %{a: 1, b: 2}
      map2 = %{a: 10, b: 20}

      {intersection, only_in_first, only_in_second} = ExBags.reconcile(map1, map2)

      assert intersection == %{a: 1, b: 2}
      assert only_in_first == %{}
      assert only_in_second == %{}
    end
  end

  describe "edge cases" do
    test "handles maps with different value types" do
      map1 = %{a: 1, b: "hello", c: [1, 2, 3]}
      map2 = %{b: "world", c: [4, 5, 6], d: :atom}

      {intersection, only_in_first, only_in_second} = ExBags.reconcile(map1, map2)

      assert intersection == %{b: "hello", c: [1, 2, 3]}
      assert only_in_first == %{a: 1}
      assert only_in_second == %{d: :atom}
    end

    test "handles maps with nil values" do
      map1 = %{a: 1, b: nil}
      map2 = %{b: nil, c: 3}

      {intersection, only_in_first, only_in_second} = ExBags.reconcile(map1, map2)

      assert intersection == %{b: nil}
      assert only_in_first == %{a: 1}
      assert only_in_second == %{c: 3}
    end
  end

  describe "intersection_stream/2" do
      test "returns stream of common key-value pairs" do
        map1 = %{a: 1, b: 2, c: 3}
        map2 = %{b: 2, c: 4, d: 5}

        result = ExBags.intersection_stream(map1, map2) |> Enum.to_list() |> Enum.sort()
        expected = [{:b, 2}, {:c, 3}]

        assert result == expected
      end

      test "returns empty stream when no common keys" do
        map1 = %{a: 1, b: 2}
        map2 = %{c: 3, d: 4}

        result = ExBags.intersection_stream(map1, map2) |> Enum.to_list()

        assert result == []
      end

      test "returns empty stream when first map is empty" do
        map1 = %{}
        map2 = %{a: 1, b: 2}

        result = ExBags.intersection_stream(map1, map2) |> Enum.to_list()

        assert result == []
      end

      test "uses value from first map when keys match but values differ" do
        map1 = %{a: 1, b: 2}
        map2 = %{a: 10, b: 20}

        result = ExBags.intersection_stream(map1, map2) |> Enum.to_list() |> Enum.sort()

        assert result == [{:a, 1}, {:b, 2}]
      end
    end

  describe "difference_stream/2" do
      test "returns stream of keys only in first map" do
        map1 = %{a: 1, b: 2, c: 3}
        map2 = %{b: 2, c: 4, d: 5}

        result = ExBags.difference_stream(map1, map2) |> Enum.to_list() |> Enum.sort()
        expected = [{:a, 1}]

        assert result == expected
      end

      test "returns empty stream when no unique keys in first map" do
        map1 = %{a: 1, b: 2}
        map2 = %{a: 1, b: 2}

        result = ExBags.difference_stream(map1, map2) |> Enum.to_list()

        assert result == []
      end

      test "returns all pairs when second map is empty" do
        map1 = %{a: 1, b: 2}
        map2 = %{}

        result = ExBags.difference_stream(map1, map2) |> Enum.to_list() |> Enum.sort()

        assert result == [{:a, 1}, {:b, 2}]
      end
    end

  describe "symmetric_difference_stream/2" do
      test "returns stream of keys in either map but not both" do
        map1 = %{a: 1, b: 2, c: 3}
        map2 = %{b: 2, c: 4, d: 5}

        result = ExBags.symmetric_difference_stream(map1, map2) |> Enum.to_list() |> Enum.sort()
        expected = [{:a, 1}, {:d, 5}]

        assert result == expected
      end

      test "returns all pairs when no common keys" do
        map1 = %{a: 1, b: 2}
        map2 = %{c: 3, d: 4}

        result = ExBags.symmetric_difference_stream(map1, map2) |> Enum.to_list() |> Enum.sort()

        assert result == [{:a, 1}, {:b, 2}, {:c, 3}, {:d, 4}]
      end

      test "returns empty stream when maps are identical" do
        map1 = %{a: 1, b: 2}
        map2 = %{a: 1, b: 2}

        result = ExBags.symmetric_difference_stream(map1, map2) |> Enum.to_list()

        assert result == []
      end

      test "excludes keys that exist in both maps regardless of values" do
        map1 = %{a: 1, b: 2}
        map2 = %{a: 10, b: 20}

        result = ExBags.symmetric_difference_stream(map1, map2) |> Enum.to_list()

        assert result == []
      end
    end

  describe "reconcile_stream/2" do
      test "returns three streams: intersection, only in first, only in second" do
        map1 = %{a: 1, b: 2, c: 3}
        map2 = %{b: 2, c: 4, d: 5}

        {common, only_first, only_second} = ExBags.reconcile_stream(map1, map2)

        assert Enum.to_list(common) |> Enum.sort() == [{:b, 2}, {:c, 3}]
        assert Enum.to_list(only_first) |> Enum.sort() == [{:a, 1}]
        assert Enum.to_list(only_second) |> Enum.sort() == [{:d, 5}]
      end

      test "returns empty intersection stream when no common keys" do
        map1 = %{a: 1, b: 2}
        map2 = %{c: 3, d: 4}

        {common, only_first, only_second} = ExBags.reconcile_stream(map1, map2)

        assert Enum.to_list(common) == []
        assert Enum.to_list(only_first) |> Enum.sort() == [{:a, 1}, {:b, 2}]
        assert Enum.to_list(only_second) |> Enum.sort() == [{:c, 3}, {:d, 4}]
      end

      test "returns all in intersection stream when maps are identical" do
        map1 = %{a: 1, b: 2}
        map2 = %{a: 1, b: 2}

        {common, only_first, only_second} = ExBags.reconcile_stream(map1, map2)

        assert Enum.to_list(common) |> Enum.sort() == [{:a, 1}, {:b, 2}]
        assert Enum.to_list(only_first) == []
        assert Enum.to_list(only_second) == []
      end

      test "handles empty maps correctly" do
        map1 = %{}
        map2 = %{a: 1, b: 2}

        {common, only_first, only_second} = ExBags.reconcile_stream(map1, map2)

        assert Enum.to_list(common) == []
        assert Enum.to_list(only_first) == []
        assert Enum.to_list(only_second) |> Enum.sort() == [{:a, 1}, {:b, 2}]
      end

      test "handles both empty maps" do
        map1 = %{}
        map2 = %{}

        {common, only_first, only_second} = ExBags.reconcile_stream(map1, map2)

        assert Enum.to_list(common) == []
        assert Enum.to_list(only_first) == []
        assert Enum.to_list(only_second) == []
      end
    end

  describe "stream laziness" do
      test "streams are lazy and can be processed incrementally" do
        map1 = %{a: 1, b: 2, c: 3, d: 4, e: 5}
        map2 = %{b: 2, c: 4, d: 6, f: 7}

        # Test that we can take only the first few elements
        intersection_stream = ExBags.intersection_stream(map1, map2)
        first_two = intersection_stream |> Stream.take(2) |> Enum.to_list()

        assert length(first_two) == 2
        assert Enum.all?(first_two, fn {key, _value} -> key in [:b, :c, :d] end)
      end

      test "streams can be filtered and transformed" do
        map1 = %{a: 1, b: 2, c: 3}
        map2 = %{b: 2, c: 4, d: 5}

        # Filter and transform the stream
        result = ExBags.intersection_stream(map1, map2)
        |> Stream.filter(fn {_key, value} -> value > 2 end)
        |> Stream.map(fn {key, value} -> {key, value * 2} end)
        |> Enum.to_list()

        assert result == [{:c, 6}]
      end
    end
  end
