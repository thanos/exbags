# ExBags

Duplicate bag (multiset) implementation for Elixir with set operations.

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:ex_bags, "~> 0.1.0"}
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
```

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

iex> stream = ExBags.intersect_stream(large_bag1, large_bag2)
iex> first_ten = stream |> Stream.take(10) |> Enum.to_list()

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

- Optimized using Elixir's built-in Map operations
- Time complexity: O(n) where n is the number of keys
- Memory efficient with lazy evaluation for streams
- Handles edge cases gracefully

## Testing

```bash
mix test
```

Test coverage:
- 33 unit tests
- 36 doctests
- 22 property tests using StreamData

Property testing validates functions with various inputs including different value types, empty bags, and large datasets.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Changelog

### 0.1.0
- Initial release
- Duplicate bag implementation with core operations
- Set operations: intersect, difference, symmetric_difference, reconcile
- Stream versions for memory-efficient processing
- Comprehensive test coverage
