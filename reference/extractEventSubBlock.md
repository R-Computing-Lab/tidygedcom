# Extract Event Sub-Block

Given a block of GEDCOM lines and a starting index corresponding to an
event tag (e.g., "BIRT" or "DEAT"), this function extracts the sub-block
of lines that are children of that event. It uses the GEDCOM level
structure to determine which lines belong to the event's sub-block,
returning all lines until it encounters a line with a level less than or
equal to the event's level.

## Usage

``` r
extractEventSubBlock(block, start_idx)
```

## Arguments

- block:

  A character vector of GEDCOM lines representing an individual's
  record.

- start_idx:

  An integer index indicating the line in the block where the event tag
  is located.

## Value

A character vector containing the lines that are part of the event's
sub-block, or an empty character vector if there are no child lines.
