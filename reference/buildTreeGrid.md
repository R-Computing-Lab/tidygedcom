# Parse Tree

Parse Tree

## Usage

``` r
buildTreeGrid(tree_lines)
```

## Arguments

- tree_lines:

  A character vector containing the lines of the tree structure.

## Value

A data frame containing the tree structure.

## Examples

``` r
buildTreeGrid(c(" | | GMa |~|y|~| GPa | ", " | | MOM |y| DAD | | "))
#>   Y1 Y2    Y3 Y4    Y5 Y6    Y7   Y8 Row
#> 1        GMa   ~     y  ~  GPa         1
#> 2        MOM   y  DAD           <NA>   2
```
