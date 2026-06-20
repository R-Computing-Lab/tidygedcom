# Parse a GEDCOM Individual Block

Processes a block of GEDCOM lines corresponding to a single individual.

## Usage

``` r
parseIndividualBlock(
  block,
  pattern_rows,
  all_var_names,
  mappings,
  verbose = FALSE
)
```

## Arguments

- block:

  A character vector containing the GEDCOM lines for one individual.

- pattern_rows:

  A list with counts of lines matching specific GEDCOM tags.

- all_var_names:

  A character vector of variable names.

- mappings:

  A named list of pre-built tag mappings as returned by
  [`make_event_fields()`](https://r-computing-lab.github.io/tidygedcom/reference/make_event_fields.md),
  [`make_name_piece_mappings()`](https://r-computing-lab.github.io/tidygedcom/reference/make_name_piece_mappings.md),
  [`make_attribute_mappings()`](https://r-computing-lab.github.io/tidygedcom/reference/make_attribute_mappings.md),
  and
  [`make_relationship_mappings()`](https://r-computing-lab.github.io/tidygedcom/reference/make_relationship_mappings.md).

- verbose:

  Logical indicating whether to print progress messages.

## Value

A named list representing the parsed record for the individual, or NULL
if no ID is found.
