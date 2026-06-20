# Build Attribute Tag Mappings

Returns a list of tag-to-field mappings for GEDCOM individual-attribute
tags (`SEX`, `CAST`, `DSCR`, `EDUC`, `IDNO`, `NATI`, `NCHI`, `NMR`,
`OCCU`, `PROP`, `RELI`, `RESI`, `SSN`, `TITL`). Build this once and pass
it to
[`parseIndividualBlock()`](https://r-computing-lab.github.io/tidygedcom/reference/parseIndividualBlock.md)
via the `mappings` argument.

## Usage

``` r
make_attribute_mappings()
```

## Value

A list of mapping entries, each with `tag`, `field`, and `mode`
elements.
