# Convert GEDCOM Coordinate Columns to Numeric

Converts all latitude and longitude columns in a parsed GEDCOM data
frame from GEDCOM compass-prefix notation (e.g., \`"N51.5074"\`,
\`"W0.1278"\`) to signed decimal degrees. By default, all columns whose
names end in \`\_lat\` or \`\_long\` are converted.

## Usage

``` r
convertGedcomCoords(df, lat_cols = NULL, long_cols = NULL)
```

## Arguments

- df:

  A data frame, typically returned by
  [`readGedcom()`](https://r-computing-lab.github.io/tidygedcom/reference/readGedcom.md).

- lat_cols:

  Character vector of latitude column names to convert. Defaults to all
  columns ending in \`"\_lat"\`.

- long_cols:

  Character vector of longitude column names to convert. Defaults to all
  columns ending in \`"\_long"\`.

## Value

The data frame with the specified columns replaced by numeric values.

## Examples

``` r
df <- data.frame(
  birth_lat = "N51.5074", birth_long = "W0.1278",
  stringsAsFactors = FALSE
)
convertGedcomCoords(df)
#>   birth_lat birth_long
#> 1   51.5074    -0.1278
```
