# Extract Year from a GEDCOM Date String

Extracts a four-digit year from a GEDCOM date string, stripping calendar
escapes (e.g., \`\\#DGREGORIAN\\\`) and common qualifiers (\`ABT\`,
\`BEF\`, \`AFT\`, \`BET\`/\`AND\`) before searching for the year.
Returns \`NA_integer\_\` when no four-digit year is found.

## Usage

``` r
extractGedcomYear(x)
```

## Arguments

- x:

  Character vector of GEDCOM date strings.

## Value

Integer vector of years.

## Examples

``` r
extractGedcomYear(c("ABT 1 JAN 1900", "BEF 31 DEC 2000", "1850", NA))
#> [1] 1900 2000 1850   NA
```
