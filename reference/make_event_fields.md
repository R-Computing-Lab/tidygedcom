# Build Event Field Mappings

Returns a named list mapping each supported GEDCOM life-event type to
the record fields it populates. Each entry has two sublists: `children`
(tags extracted from direct child lines via
[`extractInfoFromLines()`](https://r-computing-lab.github.io/tidygedcom/reference/extractInfoFromLines.md))
and `subblock` (tags searched across all descendant lines via
[`extractCoordFromSubBlock()`](https://r-computing-lab.github.io/tidygedcom/reference/extractCoordFromSubBlock.md)).
Build this once and pass it to
[`processEventLine()`](https://r-computing-lab.github.io/tidygedcom/reference/processEventLine.md)
rather than constructing it on every call.

## Usage

``` r
make_event_fields()
```

## Value

A named list with entries `birth`, `chr`, `death`, and `burial`.
