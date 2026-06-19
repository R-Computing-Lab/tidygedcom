# Extract GEDCOM Level

Extracts the GEDCOM level (the leading integer) from a line of GEDCOM
data. This is used to determine the hierarchical structure of the data
when parsing events and their sub-fields.

## Usage

``` r
extractGedcomLevel(line)
```

## Arguments

- line:

  A character string representing a line from a GEDCOM file.

## Value

An integer representing the GEDCOM level, or NA if no leading integer is
found.
