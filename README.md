# ExBags

Enhanced map operations for Elixir with set-like functions including intersection, difference, symmetric difference, and reconciliation.

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

ExBags extends Elixir's built-in Map module with powerful set-like operations that are commonly needed when working with maps as collections of key-value pairs. These operations are particularly useful for:

- Data reconciliation and synchronization
- Set operations on map keys
- Data analysis and comparison
- Database-like operations on in-memory data

## Functions

### `intersection/2`

Returns a map containing only the key-value pairs that exist in both maps.

```elixir
iex> ExBags.intersection(%{a: 1, b: 2}, %{b: 2, c: 3})
%{b: 2}

iex> ExBags.intersection(%{a: 1, b: 2}, %{b: 3, c: 4})
%{b: 2}  # Uses value from first map when keys match but values differ
```

### `difference/2`

Returns a map containing only the key-value pairs that exist in the first map but not in the second map.

```elixir
iex> ExBags.difference(%{a: 1, b: 2}, %{b: 2, c: 3})
%{a: 1}

iex> ExBags.difference(%{a: 1, b: 2}, %{a: 1, b: 2})
%{}
```

### `symmetric_difference/2`

Returns a map containing key-value pairs that exist in either map but not in both.

```elixir
iex> ExBags.symmetric_difference(%{a: 1, b: 2}, %{b: 2, c: 3})
%{a: 1, c: 3}

iex> ExBags.symmetric_difference(%{a: 1, b: 2}, %{c: 3, d: 4})
%{a: 1, b: 2, c: 3, d: 4}
```

### `reconcile/2`

Performs a reconciliation operation similar to SQL's FULL OUTER JOIN. Returns a tuple of three maps:

1. **Intersection**: Key-value pairs that exist in both maps
2. **Only in first**: Key-value pairs that exist only in the first map
3. **Only in second**: Key-value pairs that exist only in the second map

```elixir
iex> ExBags.reconcile(%{a: 1, b: 2}, %{b: 2, c: 3})
{%{b: 2}, %{a: 1}, %{c: 3}}

iex> ExBags.reconcile(%{a: 1}, %{b: 2})
{%{}, %{a: 1}, %{b: 2}}
```

## Stream Functions

For memory-efficient processing of large maps, ExBags also provides stream versions of all functions:

### `intersection_stream/2`, `difference_stream/2`, `symmetric_difference_stream/2`, `reconcile_stream/2`

These functions return streams instead of maps, allowing you to process large datasets without loading everything into memory at once.

```elixir
# Stream versions return lazy enumerables
iex> ExBags.intersection_stream(%{a: 1, b: 2}, %{b: 2, c: 3}) |> Enum.to_list()
[{:b, 2}]

# Streams can be processed incrementally
iex> stream = ExBags.intersection_stream(large_map1, large_map2)
iex> first_ten = stream |> Stream.take(10) |> Enum.to_list()

# Streams can be filtered and transformed
iex> result = ExBags.intersection_stream(map1, map2)
|> Stream.filter(fn {_key, value} -> value > 5 end)
|> Stream.map(fn {key, value} -> {key, value * 2} end)
|> Enum.to_list()

# Reconcile stream returns three streams
iex> {common, only_first, only_second} = ExBags.reconcile_stream(map1, map2)
iex> {Enum.to_list(common), Enum.to_list(only_first), Enum.to_list(only_second)}
```

## Use Cases

### Data Synchronization

```elixir
# Compare two datasets and identify changes
local_data = %{user1: %{name: "Alice", email: "alice@example.com"}}
remote_data = %{user1: %{name: "Alice", email: "alice@newdomain.com"}, user2: %{name: "Bob"}}

{common, local_only, remote_only} = ExBags.reconcile(local_data, remote_data)

# common: %{user1: %{name: "Alice", email: "alice@example.com"}}
# local_only: %{}
# remote_only: %{user2: %{name: "Bob"}}
```

### Configuration Management

```elixir
# Compare configuration versions
old_config = %{database_url: "postgres://old", api_key: "secret123", debug: true}
new_config = %{database_url: "postgres://new", api_key: "secret456", timeout: 5000}

{unchanged, removed, added} = ExBags.reconcile(old_config, new_config)

# unchanged: %{database_url: "postgres://old", api_key: "secret123"}
# removed: %{debug: true}
# added: %{timeout: 5000}
```

### Set Operations on Map Keys

```elixir
# Find common permissions between user roles
admin_perms = %{read: true, write: true, delete: true, admin: true}
user_perms = %{read: true, write: true, comment: true}

common_perms = ExBags.intersection(admin_perms, user_perms)
# %{read: true, write: true}

admin_only = ExBags.difference(admin_perms, user_perms)
# %{delete: true, admin: true}
```

## Performance Considerations

- All functions are optimized for performance and use Elixir's built-in Map operations
- Time complexity is generally O(n) where n is the number of keys in the maps
- Memory usage is efficient, creating new maps only when necessary
- Functions handle edge cases like empty maps gracefully

## Testing

Run the test suite:

```bash
mix test
```

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
- Added `intersection/2`, `difference/2`, `symmetric_difference/2`, and `reconcile/2` functions
- Comprehensive test coverage
- Full documentation
