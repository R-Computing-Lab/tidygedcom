# Build Name-Piece Tag Mappings

Returns a list of tag-to-field mappings for GEDCOM name-piece tags
(`GIVN`, `NPFX`, `NICK`, `SURN`, `NSFX`, `_MARNM`). Build this once and
pass it to
[`parseIndividualBlock()`](https://r-computing-lab.github.io/tidygedcom/reference/parseIndividualBlock.md)
via the `mappings` argument.

## Usage

``` r
make_name_piece_mappings()
```

## Value

A list of mapping entries, each with `tag`, `field`, and `mode`
elements.
