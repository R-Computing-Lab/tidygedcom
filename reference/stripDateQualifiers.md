# Strip Calendar Escapes and Approximation Qualifiers from GEDCOM Dates

Removes calendar escape codes (e.g. \`@#DGREGORIAN@\`) and the
approximation qualifiers \`ABT\`, \`AFT\`, \`BEF\`, and \`BET\` from
GEDCOM date strings, leaving the bare date behind.

The qualifier may be followed either by a period or by a word boundary,
because Ancestry.com exports write \`"Abt. Jun 1880"\` while the GEDCOM
specification uses \`"ABT JUN 1880"\`. Requiring one or the other is
what keeps the pattern from biting into ordinary words that merely begin
with those letters, such as "before".

## Usage

``` r
stripDateQualifiers(x)
```

## Arguments

- x:

  Character vector of GEDCOM date strings.

## Value

A character vector of the same length, trimmed, with escapes and
qualifiers removed.
