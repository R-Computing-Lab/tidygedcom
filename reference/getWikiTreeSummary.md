# Extract Summary Text

Extract Summary Text

## Usage

``` r
getWikiTreeSummary(text)
```

## Arguments

- text:

  A character string containing the text of a family tree in wiki
  format.

## Value

A character string containing the summary text.

## Examples

``` r
getWikiTreeSummary("{{familytree/start |summary=A three-generation example.}}")
#> [1] "A three-generation example."
```
