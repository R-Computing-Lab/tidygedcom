# Slice a Pedigree Down to the Rows Referencing an ID

Given a pedigree data frame, returns every row in which any of the
supplied IDs appears as the individual themselves, a parent, or a
spouse. This is a diagnostic aid for inspecting a person's full
household before and after manually repairing links in GEDCOM-derived
pedigrees. The result is a subset of \`ped\` with the same columns..

## Usage

``` r
sliceByID(ped, ID, sort = TRUE)
```

## Arguments

- ped:

  A pedigree data frame.

- ID:

  A vector of one or more IDs to slice on.

- sort:

  Logical. If \`TRUE\` (default), sort the result by father ID then
  individual ID.

## Value

A data frame: the subset of \`ped\` rows in which any of \`ID\` appears
in a linking column, with the original columns and names preserved.

## Details

Incoming column names are normalized with BGmisc's internal column
standardizer, so the common variants (\`ID\`/\`personID\`,
\`dadID\`/\`pid_fath\`, \`momID\`/\`pid_moth\`,
\`spID\`/\`pid_spouse1\`, ...) are all recognized without the caller
naming them. Because BGmisc's canonical schema is single-spouse but
GEDCOM-derived pedigrees often record remarriages in extra columns, any
additional spouse-like columns (matching \`spID2\`, \`pid_spouse2\`,
...) are detected and searched too. The returned rows keep the caller's
original column names.

## Examples

``` r
ped <- readGedcom(
  system.file("extdata", "waugh.ged", package = "tidygedcom"),
  verbose = FALSE
)

# Inspect William Pitt Waugh Sr. and everyone linked to him
sliceByID(ped, ID = 1)
#>   personID momID dadID                  name   name_given name_surn name_nsfx
#> 3        3     2     1    W. Henderson Waugh W. Henderson     Waugh      <NA>
#> 5        5     4     1 William Pitt Waugh Jr William Pitt     Waugh        Jr
#> 1        1  <NA>  <NA>    William Pitt Waugh William Pitt     Waugh      <NA>
#>   sex    birth_date                        birth_place    death_date
#> 3   M      abt 1835                North Carolina, USA Aft. Oct 1896
#> 5   M          1844 Wilkes County, North Carolina, USA      Feb 1880
#> 1   M 28 April 1775    Adams County, Pennsylvania, USA   14 Aug 1852
#>                          death_place                            burial_place
#> 3 Wilkes County, North Carolina, USA                                    <NA>
#> 5   Henderson County, Tennessee, USA                                    <NA>
#> 1 Wilkes County, North Carolina, USA Wilkesboro, Wilkes, North Carolina, USA
#>   FAMC FAMS
#> 3    1    3
#> 5    2    4
#> 1 <NA> 1, 2
```
