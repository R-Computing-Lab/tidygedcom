# Find Where One or More IDs Occur Across a List of Data Frames

Searches a named list of data frames for the supplied IDs, looking in
every column whose name matches \`id_regex\` (parent, spouse, and
person-ID columns by default). Returns one row per hit, recording which
dataset, which column, and which row the ID was found in, alongside any
requested context columns. This is the detective step of link repair:
locating every place an ID lives before deciding how to fix it.

## Usage

``` r
findIDs(
  data_list,
  ID,
  id_regex = "(^id$|id$|^pid|pid$|pid_|dadid|momid|patid|matid|spid|spouse|sire|dame)",
  context_cols = c("sex", "byr", "dyr", "name"),
  ignore_case = TRUE,
  include_all_id_cols = FALSE
)
```

## Arguments

- data_list:

  A named list of data frames to search.

- ID:

  A vector of one or more IDs to search for.

- id_regex:

  Regular expression matched against column names to decide which
  columns are ID columns. Ignored when \`include_all_id_cols = TRUE\`.

- context_cols:

  Character vector of additional (non-ID) columns to carry through for
  context. Columns absent from a given data frame are ignored.

- ignore_case:

  Logical. Match \`id_regex\` case-insensitively. Default \`TRUE\`.

- include_all_id_cols:

  Logical. If \`TRUE\`, search every column rather than only those
  matching \`id_regex\`. Default \`FALSE\`.

## Value

A data frame with one row per match, containing \`matched_id\`,
\`dataset\`, \`matched_column\`, \`matched_value\`, the source
\`row_index\`, and any available \`context_cols\`. Returns an empty data
frame if nothing matches.

## Details

Unlike \[sliceByID()\], this does \*not\* standardise column names,
because its whole purpose is to catch IDs wherever they hide, including
in non-canonical columns.

## Examples

``` r
if (FALSE) { # \dontrun{
findIDs(list(clean = clean_df, raw = raw_df), ID = 389785)
} # }
```
