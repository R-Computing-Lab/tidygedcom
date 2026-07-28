# Read Wiki Family Tree

Read Wiki Family Tree

## Usage

``` r
readWikifamilytree(text = NULL, verbose = FALSE, file_path = NULL, ...)
```

## Arguments

- text:

  A character string containing the text of a family tree in wiki
  format.

- verbose:

  A logical value indicating whether to print messages.

- file_path:

  The path to the file containing the family tree.

- ...:

  Additional arguments (not used).

## Value

A list containing the summary, members, structure, and relationships of
the family tree.

## Examples

``` r
tree_text <- paste(
  "{{familytree/start |summary=A three-generation example.}}",
  "{{familytree | | | | GMa |~|y|~| GPa | | GMa=Gladys|GPa=Sydney}}",
  "{{familytree | | | | | | | |)|-|-|-|.| }}",
  "{{familytree | | | MOM |y| DAD | |AUNT| MOM=Mom|DAD=Dad|AUNT=Aunt Daisy}}",
  "{{familytree | |,|-|-|-|.| | | | | | }}",
  "{{familytree | JOE | | ME  | | JOE=Joe|ME=Me}}",
  "{{familytree/end}}",
  sep = "\n"
)

tree <- readWikifamilytree(text = tree_text)
tree$summary
#> [1] "A three-generation example."
head(tree$members)
#>   identifier       name id
#> 2        GMa     Gladys P1
#> 3        GPa     Sydney P2
#> 4        MOM        Mom P3
#> 5        DAD        Dad P4
#> 6       AUNT Aunt Daisy P5
#> 7        JOE        Joe P6
```
