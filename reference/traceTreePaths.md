# Trace paths between individuals in a family tree grid

Trace paths between individuals in a family tree grid

## Usage

``` r
traceTreePaths(tree_long, deduplicate = TRUE)
```

## Arguments

- tree_long:

  A data.frame with columns: Row, Column, Value, id

- deduplicate:

  Logical, if TRUE, will remove duplicate paths

## Value

A data.frame with columns: from_id, to_id, direction, path_length,
intermediates

## Examples

``` r
# Two individuals joined by a horizontal connector
tree_long <- data.frame(
  Row = rep(1, 3),
  Column = 1:3,
  Value = c("A", "+", "B"),
  id = c("A", NA, "B")
)

traceTreePaths(tree_long)
#>   from_id to_id path_length intermediates intermediate_values
#> 1       A     B           2           1_2                   +
```
