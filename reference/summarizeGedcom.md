# Summarize a Parsed GEDCOM Data Frame

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
df <- readGedcom(
  system.file("extdata", "waugh.ged", package = "tidygedcom"),
  verbose = FALSE
)
summarizeGedcom(df)
#> GEDCOM Summary  (version: 5.5.1 )
#>   Individuals: 8 
#>   Sex: M = 5 | F = 3 | Unknown = 0 
#>   With birth date: 8  (100%) 
#>   With death date: 7  (88%) 
#>   With birth place: 7  (88%) 
#>   With death place: 7  (88%) 
#>   With known mother: 3  (38%) 
#>   With known father: 4  (50%) 

# Coverage drops on a file with missing records
messy <- readGedcom(
  system.file("extdata", "waugh_messy.ged", package = "tidygedcom"),
  verbose = FALSE
)
summarizeGedcom(messy)
#> GEDCOM Summary  (version: 5.5.1 )
#>   Individuals: 8 
#>   Sex: M = 5 | F = 2 | Unknown = 1 
#>   With birth date: 7  (88%) 
#>   With death date: 7  (88%) 
#>   With birth place: 6  (75%) 
#>   With death place: 7  (88%) 
#>   With known mother: 2  (25%) 
#>   With known father: 4  (50%) 
```
