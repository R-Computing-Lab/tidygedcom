# Parse a GEDCOM Family Block

Parse a GEDCOM Family Block

## Usage

``` r
parseFamilyBlock(block, verbose = FALSE)
```

## Arguments

- block:

  Character vector of GEDCOM lines for one FAM record.

- verbose:

  Logical. Currently unused.

## Value

A named list with family fields, or \`NULL\` if no family ID is found.
