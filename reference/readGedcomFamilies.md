# Read Family Records from a GEDCOM File

Parses \`FAM\` records from a GEDCOM file and returns a tidy data frame
with one row per family unit. Captures husband, wife, children, marriage
event, and divorce event details.

## Usage

``` r
readGedcomFamilies(
  file_path,
  verbose = FALSE,
  parse_dates = FALSE,
  remove_empty_cols = TRUE,
  ...
)
```

## Arguments

- file_path:

  Character string. Path to the GEDCOM file.

- verbose:

  Logical. If \`TRUE\`, print progress messages.

- parse_dates:

  Logical. If \`TRUE\`, attempt to parse \`marr_date\` and \`div_date\`
  into \`Date\` objects, after stripping common GEDCOM qualifiers.

- remove_empty_cols:

  Logical indicating whether to remove columns that are entirely
  missing.

- ...:

  Additional arguments. Currently unused.

## Value

A data frame with one row per \`FAM\` record and the following columns:

- famID:

  Family identifier from the \`@ FAM\` line.

- husbID:

  Person ID of the husband (\`HUSB\` tag).

- wifeID:

  Person ID of the wife (\`WIFE\` tag).

- children:

  Comma-separated person IDs of children (\`CHIL\` tags).

- marr_date:

  Marriage date (\`MARR/DATE\`).

- marr_place:

  Marriage place (\`MARR/PLAC\`).

- marr_lat:

  Marriage latitude (\`MARR/.../LATI\`).

- marr_long:

  Marriage longitude (\`MARR/.../LONG\`).

- div_date:

  Divorce date (\`DIV/DATE\`).

- div_place:

  Divorce place (\`DIV/PLAC\`).

Returns \`NULL\` with a warning if no family records are found.
