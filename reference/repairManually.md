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
# The messy example file omits Laura Watkins's SEX line, so she cannot be
# resolved as a mother during parsing.
ped <- readGedcom(
  system.file("extdata", "waugh_messy.ged", package = "tidygedcom"),
  verbose = FALSE
)
ped$sex[ped$personID == 6]
#> [1] NA

fixes <- list(
  laura_sex = list(
    rows = rlang::quo(personID == 6),
    changes = list(sex = "F"),
    comment = "Sex absent from source export; confirmed by 1880 census."
  )
)
ped <- repairManually(ped, fixes)
ped[ped$personID == 6, c("personID", "name", "sex", "manual_fix")]
#>   personID          name sex manual_fix
#> 6        6 Laura Watkins   F  laura_sex
```
