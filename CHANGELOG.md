# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-12-19

### Added
- **Comprehensive Benchmarking System**
  - Added `Benchee` dependency for performance testing
  - Created organized benchmark scripts in `priv/scripts/benchmarks/` directory
  - Added mix aliases for easy benchmark execution:
    - `mix benchmark` - Run all benchmarks
    - `mix benchmark.intersect` - Compare Map, MapSet, ExBags intersect
    - `mix benchmark.stream` - Compare ExBags stream vs eager
    - `mix benchmark.all` - Run all benchmarks
  - Added performance analysis scripts with detailed explanations

- **Performance Analysis and Documentation**
  - Comprehensive performance comparison tables in README
  - Detailed analysis of stream vs eager performance characteristics
  - Memory usage analysis across different dataset sizes
  - Optimization recommendations for different use cases
  - Performance characteristics explanation for when to use each approach

- **Test Coverage Reporting**
  - Added `ExCoveralls` dependency for code coverage
  - Integrated coverage reporting with `mix coveralls.html`
  - Achieved 100% code coverage across all functions
  - Added coverage configuration in `.coveralls.json`

- **Enhanced Documentation**
  - Updated README with detailed performance metrics
  - Added benchmarking instructions and usage examples
  - Comprehensive performance analysis section
  - Stream optimization guidelines and best practices

### Changed
- **Stream Performance Analysis**
  - Identified and documented why streams appear slower in benchmarks
  - Explained `Enum.to_list()` overhead in stream benchmarks
  - Provided realistic usage patterns for stream operations
  - Added performance characteristics by dataset size

- **Benchmark Organization**
  - Moved all benchmark scripts to organized `benchmarks/` directory
  - Separated intersect and stream benchmarks into focused scripts
  - Created main benchmark runner with proper module structure
  - Added performance analysis and README update scripts

### Performance Improvements
- **Stream Operations**: 1.6x to 330x faster than eager for large datasets
- **Memory Efficiency**: Streams provide constant memory usage vs peak memory for eager
- **Optimization Guidelines**: Clear recommendations for dataset size thresholds

### Technical Details
- **Intersect Performance**: MapSet > ExBags > Map across all dataset sizes
- **Memory Usage**: Scales with data size, streams reduce peak memory usage
- **Time Complexity**: O(n) where n is the number of keys
- **Stream Overhead**: Higher per-operation cost but better for large datasets

## [0.1.3] - 2024-12-19

### Added
- **Duplicate Bag (Multiset) Support**
  - Implemented core bag operations: `put`, `get`, `keys`, `values`, `new`, `update`
  - Added multiset semantics for all set operations
  - Support for multiple values per key as lists

- **Enhanced Set Operations**
  - Renamed `intersection` to `intersect` for consistency
  - Updated `intersect` to return tuple of values for common keys: `{values1, values2}`
  - Modified `reconcile` to use actual value intersection for common part
  - Added `bag_intersection` helper function for multiset value intersection

- **Stream Support**
  - Implemented stream versions of all set operations
  - Added `intersect_stream`, `difference_stream`, `symmetric_difference_stream`, `reconcile_stream`
  - Memory-efficient processing for large datasets

- **Property Testing**
  - Added comprehensive property-based testing with `StreamData`
  - 22 property tests covering various input scenarios
  - Tests for different value types, empty bags, and large datasets
  - Validation of multiset semantics and edge cases

### Changed
- **API Changes**
  - `intersect/2` now returns `%{key => {values1, values2}}` instead of merged values
  - `reconcile/2` uses actual value intersection for common keys
  - All functions adapted to work with duplicate bag semantics

- **Test Coverage**
  - Updated all unit tests to reflect new multiset behavior
  - Enhanced property tests for tuple-based intersect results
  - Fixed property test assertions for multiset operations

### Fixed
- **Bug Fixes**
  - Fixed `intersect` function to perform key intersection with tuple values
  - Corrected `reconcile` to use proper value intersection for common part
  - Fixed property test calculations for symmetric difference
  - Resolved `Enumerable` protocol errors in stream benchmarks

## [0.1.0] - 2024-12-19

### Added
- **Initial Release**
  - Basic map wrapper with set-like operations
  - `intersection`, `difference`, `symmetric_difference`, `reconcile` functions
  - Stream versions of all operations
  - SQL FULL OUTER JOIN semantics for `reconcile`
  - Comprehensive documentation and examples
  - Hex.pm package configuration
  - MIT License

### Features
- **Core Operations**
  - `intersection/2` - Find common keys and values
  - `difference/2` - Find keys only in first map
  - `symmetric_difference/2` - Find keys in either map but not both
  - `reconcile/2` - Full outer join returning `{common, only_a, only_b}`

- **Stream Support**
  - Lazy evaluation for memory efficiency
  - Stream versions of all set operations
  - Suitable for large datasets

- **Documentation**
  - Comprehensive README with examples
  - Function documentation with doctests
  - Usage patterns and best practices

---

## Migration Guide

### From 0.1.x to 0.2.0

No breaking changes in this version. All existing APIs remain compatible.

### From 0.1.0 to 0.1.3

**Breaking Changes:**
- `intersection/2` renamed to `intersect/2`
- `intersect/2` now returns tuples: `%{key => {values1, values2}}`
- All functions now work with duplicate bag semantics (lists of values per key)

**Migration Steps:**
1. Replace `ExBags.intersection/2` with `ExBags.intersect/2`
2. Update code expecting merged values to handle tuple format
3. Convert single values to lists when using bag operations

**Example Migration:**
```elixir
# Before (0.1.0)
result = ExBags.intersection(%{a: 1, b: 2}, %{b: 3, c: 4})
# %{b: 2}

# After (0.1.3+)
result = ExBags.intersect(%{a: [1], b: [2]}, %{b: [3], c: [4]})
# %{b: {[2], [3]}}
```
