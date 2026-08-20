# Extract Year from a GEDCOM Date String

Extracts a four-digit year from a GEDCOM date string, stripping calendar
escapes (e.g., \`\\#DGREGORIAN\\\`) and common qualifiers (\`ABT\`,
\`BEF\`, \`AFT\`, \`BET\`/\`AND\`) before searching for the year.
Returns \`NA_integer\_\` when no year is found. The function can be used
to extract years from various GEDCOM date formats, including approximate
dates and date ranges.

## Usage

``` r
extractGedcomYear(x, year_len = 4)
```

## Arguments

- x:

  Character vector of GEDCOM date strings.

- year_len:

  Integer specifying the length of the year to extract (default is 4).

## Value

Integer vector of years.

## Examples

``` r
extractGedcomYear(c("ABT 1 JAN 1900", "BEF 31 DEC 2000", "1850", NA))
#> [1] 1900 2000 1850   NA
```
