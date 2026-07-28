# tidygedcom

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R package
version](https://www.r-pkg.org/badges/version/tidygedcom)](https://cran.r-project.org/package=tidygedcom)
[![CRAN
checks](https://badges.cranchecks.info/worst/tidygedcom.svg)](https://cran.r-project.org/web/checks/check_results_tidygedcom.html)
[![Package
downloads](https://cranlogs.r-pkg.org/badges/grand-total/tidygedcom)](https://cran.r-project.org/package=tidygedcom)
[![R-CMD-check](https://github.com/R-Computing-Lab/tidygedcom/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/R-Computing-Lab/tidygedcom/actions/workflows/R-CMD-check.yaml)
[![CodeFactor](https://www.codefactor.io/repository/github/r-computing-lab/tidygedcom/badge)](https://www.codefactor.io/repository/github/r-computing-lab/tidygedcom)
[![Codecov test
coverage](https://codecov.io/gh/R-Computing-Lab/tidygedcom/graph/badge.svg?token=2IARK2XSA6)](https://app.codecov.io/gh/R-Computing-Lab/tidygedcom)
![License](https://img.shields.io/badge/License-GPL_v3-blue.svg)

tidygedcom reads GEDCOM (Genealogical Data Communication) files – the
standard format exported by genealogical software such as Ancestry.com,
MyHeritage, and Gramps – and converts them into tidy data frames.
Individuals, families, life events, and parent-child links are extracted
into rectangular structures ready for pedigree and kinship analysis. The
package also summarizes file contents, converts place coordinates,
repairs malformed records, and parses Wikipedia family tree templates
into the same structure.

tidygedcom is a companion to
[BGmisc](https://cran.r-project.org/package=BGmisc), which handles
pedigree modeling and relatedness calculation, and
[ggpedigree](https://cran.r-project.org/package=ggpedigree), which
handles plotting. tidygedcom focuses solely on getting genealogical data
*into* R in a usable shape.

## Example

``` r

library(tidygedcom)

ged <- readGedcom(
  system.file("extdata", "waugh.ged", package = "tidygedcom"),
  verbose = FALSE
)

ged[, c("personID", "name", "sex", "birth_date", "momID", "dadID")]
#>   personID                     name sex    birth_date momID dadID
#> 1        1       William Pitt Waugh   M 28 April 1775  <NA>  <NA>
#> 2        2          Matilda Grinton   F      abt 1797  <NA>  <NA>
#> 3        3       W. Henderson Waugh   M      abt 1835     2     1
#> 4        4      Martha Law Segraves   F      Oct 1814  <NA>  <NA>
#> 5        5    William Pitt Waugh Jr   M          1844     4     1
#> 6        6            Laura Watkins   F      abt 1846  <NA>  <NA>
#> 7        7 John William "Bud" Waugh   M   13 Dec 1879     6     3
#> 8        8       James Monroe Waugh   M   10 Nov 1867  <NA>     5
```

The package ships two example files drawn from the W. Henderson Waugh
Family Tree: `waugh.ged` is a clean excerpt, and `waugh_messy.ged`
retains the defects typical of a real export (conflicting duplicate
birth records, missing sex values, uncertain surnames) for testing how
your code handles imperfect input.

## Installation

You can install the released version of tidygedcom from
[CRAN](https://cran.r-project.org/) with:

``` r

install.packages("tidygedcom")
```

To install the development version of tidygedcom from
[GitHub](https://github.com/) use:

``` r

# install.packages("devtools")
devtools::install_github("R-Computing-Lab/tidygedcom")
```

## Citation

If you use tidygedcom in your research or wish to refer to it, please
cite the following paper:

``` R
citation(package = "tidygedcom")
```

Garrison S, Waugh C (2026). *tidygedcom: Read and Tidy ‘GEDCOM’
Genealogy Files*. R package version 0.1.0,
<https://github.com/R-Computing-Lab/tidygedcom/>.

A BibTeX entry for LaTeX users is

``` R
@Manual{,
  title = {tidygedcom: Read and Tidy 'GEDCOM' Genealogy Files},
  author = {S. Mason Garrison and Christian Waugh},
  year = {2026},
  note = {R package version 0.1.0},
  url = {https://github.com/R-Computing-Lab/tidygedcom/},
}
```

## Contributing

Contributions to the tidygedcom project are welcome. For guidelines on
how to contribute, please refer to the [Contributing
Guidelines](https://github.com/R-Computing-Lab/tidygedcom/blob/main/CONTRIBUTING.md).
Issues and pull requests should be submitted on the GitHub repository.
For support, please use the GitHub issues page.

### Branching and Versioning System

The development of tidygedcom follows a [GitFlow branching
strategy](https://docs.gitlab.com/user/project/repository/branches/strategies/):

- **Feature Branches**: All major changes and new features should be
  developed on separate branches created from the dev_main branch. Name
  these branches according to the feature or change they are meant to
  address.
- **Development Branches**: Our approach includes two development
  branches, each serving distinct roles:
  - **`dev_main`**: This branch is the final integration stage before
    changes are merged into the `main` branch. It is considered stable,
    and only well-tested features and updates that are ready for the
    next release cycle are merged here.
  - **`dev`**: This branch serves as a less stable, active development
    environment. Feature branches are merged here. Changes here are more
    fluid and this branch is at a higher risk of breaking.
- **Main Branch** (`main`): The main branch mirrors the stable state of
  the project as seen on CRAN. Only fully tested and approved changes
  from the dev_main branch are merged into main to prepare for a new
  release.

## License

tidygedcom is licensed under the GNU General Public License v3.0. For
more details, see the
[LICENSE.md](https://github.com/R-Computing-Lab/tidygedcom/blob/main/LICENSE.md)
file.
