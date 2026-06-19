# Assign momID and dadID based on family mapping

This function assigns mother and father IDs to individuals in the data
frame based on the mapping of family IDs to parent IDs. It updates the
data frame in place.

## Usage

``` r
mapFAMC2parents(df_temp, family_to_parents)
```

## Arguments

- df_temp:

  A data frame produced by
  [`readGedcom()`](https://r-computing-lab.github.io/tidygedcom/reference/readGedcom.md).

- family_to_parents:

  A list mapping family IDs to parent IDs.

## Value

A data frame with added momID and dad_ID columns.
