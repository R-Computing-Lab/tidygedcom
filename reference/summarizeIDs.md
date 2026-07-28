# Summarize Where One or More IDs Occur Across a List of Data Frames

A count-level companion to \[findIDs()\]: instead of one row per hit,
returns one row per (id, dataset, column) with the number of matches.
Useful for a quick census of how many places an ID appears before
drilling in with \[findIDs()\].

## Usage

``` r
summarizeIDs(data_list, ID, ...)

summariseIDs(data_list, ID, ...)
```

## Arguments

- data_list:

  A named list of data frames to search.

- ID:

  A vector of one or more IDs to search for.

- ...:

  Additional arguments passed to \[findIDs()\].

## Value

A data frame with columns \`matched_id\`, \`dataset\`,
\`matched_column\`, and \`n_matches\`.

## Examples

``` r
clean <- readGedcom(
  system.file("extdata", "waugh.ged", package = "tidygedcom"),
  verbose = FALSE
)
messy <- readGedcom(
  system.file("extdata", "waugh_messy.ged", package = "tidygedcom"),
  verbose = FALSE
)

# Count references per dataset and column
summarizeIDs(list(clean = clean, messy = messy), ID = 3)
#> # A tibble: 4 × 4
#>   matched_id dataset matched_column n_matches
#>   <chr>      <chr>   <chr>              <int>
#> 1 3          clean   dadID                  1
#> 2 3          clean   personID               1
#> 3 3          messy   dadID                  1
#> 4 3          messy   personID               1
```
