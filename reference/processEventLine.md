# Process Event Lines (Birth or Death)

Extracts event details (e.g., date, place, cause, latitude, longitude)
from a block of GEDCOM lines. Uses level-aware sub-block parsing so
fields are looked up by tag name rather than fixed offsets.

## Usage

``` r
processEventLine(event, block, i, record, pattern_rows, event_fields)
```

## Arguments

- event:

  A character string indicating the event type ("birth", "chr", "death",
  or "burial").

- block:

  A character vector of GEDCOM lines.

- i:

  The current line index where the event tag is found.

- record:

  A named list representing the individual's record.

- pattern_rows:

  A list with counts of GEDCOM tag occurrences.

- event_fields:

  A named list of field mappings as returned by
  [`make_event_fields()`](https://r-computing-lab.github.io/tidygedcom/reference/make_event_fields.md).

## Value

The updated record with parsed event information.
