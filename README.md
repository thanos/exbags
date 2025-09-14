# ExBags

A duplicate bag (multiset) implementation for Elixir with powerful set-like operations including intersect, difference, symmetric difference, and reconciliation.

## Installation

Add `ex_bags` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_bags, "~> 0.1.0"}
  ]
end
```

## Overview

ExBags provides a duplicate bag implementation that allows multiple values for the same key, along with set-like operations for working with these multisets. A duplicate bag is like a map but stores values as lists, enabling you to track multiple occurrences of the same value for each key.

These operations are particularly useful for:

- Data reconciliation and synchronization
- Multiset operations and counting
- Data analysis and comparison
- Database-like operations on in-memory data
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

Returns a bag containing only the key-value pairs that exist in both bags.

```elixir
iex> ExBags.intersect(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
%{b: [2]}

iex> ExBags.intersect(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1, 2], b: [2, 4]})
%{a: [1, 2], b: [2]}
```

### `difference/2`

Returns a bag containing only the key-value pairs that exist in the first bag but not in the second bag.

```elixir
iex> ExBags.difference(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
%{a: [1, 2], b: [3]}

iex> ExBags.difference(%{a: [1, 1, 2], b: [2, 2, 3]}, %{a: [1], b: [2]})
%{a: [1, 2], b: [2, 3]}
```

### `symmetric_difference/2`

Returns a bag containing key-value pairs that exist in either bag but not in both.

```elixir
iex> ExBags.symmetric_difference(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
%{a: [1, 2], b: [3, 4], c: [5]}

iex> ExBags.symmetric_difference(%{a: [1, 1, 2]}, %{a: [1, 2, 2]})
%{a: [1, 2]}
```

### `reconcile/2`

Performs a reconciliation operation similar to SQL's FULL OUTER JOIN for duplicate bags. Returns a tuple of three bags:

1. Intersection: Key-value pairs that exist in both bags
2. Only in first: Key-value pairs that exist only in the first bag
3. Only in second: Key-value pairs that exist only in the second bag

```elixir
iex> ExBags.reconcile(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]})
{%{b: [2]}, %{a: [1, 2], b: [3]}, %{b: [4], c: [5]}}

iex> ExBags.reconcile(%{a: [1]}, %{b: [2]})
{%{}, %{a: [1]}, %{b: [2]}}
```

## Stream Functions

For memory-efficient processing of large bags, ExBags also provides stream versions of all functions:

### `intersect_stream/2`, `difference_stream/2`, `symmetric_difference_stream/2`, `reconcile_stream/2`

These functions return streams instead of bags, allowing you to process large datasets without loading everything into memory at once.

```elixir
# Stream versions return lazy enumerables
iex> ExBags.intersect_stream(%{a: [1, 2], b: [2, 3]}, %{b: [2, 4], c: [5]}) |> Enum.to_list() |> Enum.sort()
[{:b, [2]}]

# Streams can be processed incrementally
iex> stream = ExBags.intersect_stream(large_bag1, large_bag2)
iex> first_ten = stream |> Stream.take(10) |> Enum.to_list()

# Streams can be filtered and transformed
iex> result = ExBags.intersect_stream(bag1, bag2)
...> |> Stream.filter(fn {_key, values} -> length(values) > 1 end)
...> |> Stream.map(fn {key, values} -> {key, Enum.map(values, &(&1 * 2))} end)
...> |> Enum.to_list()

# Reconcile stream returns three streams
iex> {common, only_first, only_second} = ExBags.reconcile_stream(bag1, bag2)
iex> {Enum.to_list(common) |> Enum.sort(), Enum.to_list(only_first) |> Enum.sort(), Enum.to_list(only_second) |> Enum.sort()}
```

## Use Cases

### Inventory Management

```elixir
# Track multiple items of the same type
inventory = ExBags.new()
inventory = ExBags.put(inventory, :apples, "red")
inventory = ExBags.put(inventory, :apples, "green")
inventory = ExBags.put(inventory, :bananas, "yellow")

# Check what we have
ExBags.get(inventory, :apples)
# ["red", "green"]

# Find items that appear in both inventories
common_items = ExBags.intersect(warehouse_inventory, store_inventory)
```

### Data Synchronization

```elixir
# Compare two datasets with multiple values per key
local_data = %{users: ["alice", "bob"], sessions: ["session1", "session2"]}
remote_data = %{users: ["alice", "charlie"], sessions: ["session2", "session3"]}

{common, local_only, remote_only} = ExBags.reconcile(local_data, remote_data)

# common: %{users: ["alice"], sessions: ["session2"]}
# local_only: %{users: ["bob"], sessions: ["session1"]}
# remote_only: %{users: ["charlie"], sessions: ["session3"]}
```

### Event Tracking

```elixir
# Track multiple events per user
events = ExBags.new()
events = ExBags.put(events, :user1, "login")
events = ExBags.put(events, :user1, "view_page")
events = ExBags.put(events, :user2, "login")

# Find users with common events
common_events = ExBags.intersect(user_events, admin_events)
```

## Performance Considerations

- All functions are optimized for performance and use Elixir's built-in Map operations
- Time complexity is generally O(n) where n is the number of keys in the bags
- Memory usage is efficient, creating new bags only when necessary
- Functions handle edge cases like empty bags and empty value lists gracefully
- Duplicate bag operations use frequency counting for efficient multiset operations

## Testing

Run the test suite:

```bash
mix test
```

The test suite includes:
- Unit Tests: 33 comprehensive unit tests covering all functions
- Doctests: 36 doctests embedded in the documentation
- Property Tests: 22 property-based tests using StreamData for comprehensive validation

Property testing ensures the functions work correctly with a wide variety of inputs, including:
- Bags with different value types (integers, strings, booleans, atoms)
- Bags with nil values and empty lists
- Empty bags and edge cases
- Large datasets and various key combinations
- Stream laziness and composition properties
- Multiset operations with duplicate values

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### 0.1.0
- Initial release
- Added duplicate bag (multiset) implementation with core operations: `new/0`, `put/3`, `get/2`, `keys/1`, `values/1`, `update/3`
- Added set operations: `intersect/2`, `difference/2`, `symmetric_difference/2`, and `reconcile/2`
- Added stream versions of all operations for memory-efficient processing
- Comprehensive test coverage with unit tests, doctests, and property tests
- Full documentation with examples
