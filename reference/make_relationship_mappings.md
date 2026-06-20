# Build Relationship Tag Mappings

Returns a list of tag-to-field mappings for GEDCOM family-relationship
tags (`FAMC`, `FAMS`). Each entry includes a custom extractor that pulls
the numeric family ID from the cross-reference pointer. Build this once
and pass it to
[`parseIndividualBlock()`](https://r-computing-lab.github.io/tidygedcom/reference/parseIndividualBlock.md)
via the `mappings` argument.

## Usage

``` r
make_relationship_mappings()
```

## Value

A list of mapping entries, each with `tag`, `field`, `mode`, and
`extractor` elements.
