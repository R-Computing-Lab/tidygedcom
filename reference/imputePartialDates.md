# Impute a Day (and Month) for Partial GEDCOM Dates

Historical genealogical records are frequently precise only to the month
or the year: a birth year reconstructed from a census age question, or a
death month taken from a probate filing. \`as.Date()\` requires a day
component, so such dates would otherwise be dropped entirely.

This helper fills in the missing components with the midpoint of the
known interval – the 15th for a known month, and 15 June for a known
year only – which minimizes the expected error of the imputed value.
Values that already carry a day, and values that match neither pattern,
are returned unchanged.

Callers should strip calendar escapes and qualifiers (\`ABT\`, \`BEF\`,
\`AFT\`) before calling this function.

## Usage

``` r
imputePartialDates(x, default_day = "15", default_month = "JUN")
```

## Arguments

- x:

  Character vector of GEDCOM date strings.

- default_day:

  Character string of the day to impute for month-precision dates
  (default \`"15"\`). @param default_month Character string of the month
  to impute for year-precision

## Value

A character vector of the same length, with month- and year-precision
entries expanded to a full \`"

## Examples

``` r
tidygedcom:::imputePartialDates(c("Oct 1814", "1844", "28 Apr 1775", NA))
#> [1] "15 Oct 1814" "15 JUN 1844" "28 Apr 1775" NA           
```
