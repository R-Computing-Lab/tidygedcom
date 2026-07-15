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
if (FALSE) { # \dontrun{
summarizeIDs(list(clean = clean_df, raw = raw_df), ID = 389785)
} # }
```
