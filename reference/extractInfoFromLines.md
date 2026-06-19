# Extract Information from Lines by Tag

Given a set of lines (e.g., direct children of an event) and a GEDCOM
tag, this function searches for the first line that contains the tag as
a whole word and extracts the relevant information using the
\`extractInfo()\` function. If no matching line is found, it returns
\`NA_character\_\`.

## Usage

``` r
extractInfoFromLines(lines, tag)
```

## Arguments

- lines:

  A character vector of GEDCOM lines to search through.

- tag:

  A character string representing the GEDCOM tag to look for (e.g
  "DATE", "PLAC", "CAUS").

## Value

A character string with the extracted information from the first
matching line, or \`NA_character\_\` if no matching line is found.
