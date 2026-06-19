# Summarise a Parsed GEDCOM Data Frame

Returns key counts and coverage statistics for a data frame produced by
[`readGedcom()`](https://r-computing-lab.github.io/tidygedcom/reference/readGedcom.md).

## Usage

``` r
summarizeGedcom(df)
```

## Arguments

- df:

  A data frame returned by
  [`readGedcom()`](https://r-computing-lab.github.io/tidygedcom/reference/readGedcom.md).

## Value

An object of class `"tidygedcom_summary"` (a named list). Print the
result for a human-readable overview.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- readGedcom("my_file.ged")
summarizeGedcom(df)
} # }
```
