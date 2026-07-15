# Apply a List of Hand-Verified Fixes to a Pedigree

Applies a set of manual corrections to a pedigree data frame, recording
the provenance of each edit in \`manual_fix\` and \`manual_fix_comment\`
columns and refusing to let two fixes silently touch the same row. This
is the repair counterpart to BGmisc's automated \[BGmisc::repairIDs()\]
/ \[BGmisc::repairSex()\]: for the cases a human has to resolve by hand,
it keeps the edits reproducible and auditable.

## Usage

``` r
repairManually(ped, fixes)
```

## Arguments

- ped:

  A pedigree data frame.

- fixes:

  A named list of fixes, each structured as described above. The names
  label each fix and are stored in \`manual_fix\`.

## Value

\`ped\` with the fixes applied and the \`manual_fix\` /
\`manual_fix_comment\` provenance columns populated.

## Details

Each element of \`fixes\` is itself a list with three parts:

- rows:

  A quoted expression (see \[rlang::quo()\]) that evaluates within
  \`ped\` to a logical row selector, e.g. \`rlang::quo(ID == 348700)\`.

- changes:

  A named list of \`column = new_value\` pairs to assign to the selected
  rows.

- comment:

  A short human-readable note explaining the fix.

## Examples

``` r
if (FALSE) { # \dontrun{
fixes <- list(
  swap_parents = list(
    rows = rlang::quo(ID == 348700),
    changes = list(momID = 348701, dadID = NA),
    comment = "Verified against parish record."
  )
)
ped <- repairManually(ped, fixes)
} # }
```
