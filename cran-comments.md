# Description

This is a new submission that splits some functions and a dataset from the BGmisc package into a new package called tidygedcom. tidygedcom focuses on reading and parsing GEDCOM files, which are used to represent genealogical data. The package provides functions to read GEDCOM files, parse individual records, and convert the data into a tidy format for analysis. Unlike BGmisc, tidygedcom does not include functions for modeling pedigrees or other genealogical analyses. The package is designed to be fast and memory-efficient, making it suitable for working with large pedigrees as well as being compatible with the Tidyverse ecosystem. The package is intended for use by genealogists, researchers, and anyone interested in working with genealogical data in R.

Once this package is on CRAN, the BGmisc package will be updated to remove the functions that have been moved to tidygedcom. The BGmisc package will continue to provide functions for modeling pedigrees and other genealogical analyses, while tidygedcom will focus on reading and parsing GEDCOM files. We implemented a similar spinoff of plotting functions from BGmisc to ggpedigree, which is now on CRAN. Like ggpedigree, the tidygedcom package is intended to be a companion package to BGmisc, providing a streamlined and efficient way to read and parse gedcom files for genealogical analysis. 

# Test Environments

1. Local OS: Windows 11 x64 (build 26220), R 4.6.1 (2026-06-24 ucrt)
2. **GitHub Actions**:  
    - [Link](https://github.com/R-Computing-Lab/tidygedcom/actions/runs/23058399384)
    - macOS (latest version) with the latest R release.
    - Windows (latest version) with the latest R release.
    - Ubuntu (latest version) with:
        - The development version of R.
        - The latest R release.

## R CMD check results


── R CMD check results ─────────────────────────────────────── tidygedcom 0.1.0 ────
Duration: 1m 31.4s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔


## Method references

There are no published references describing the methods in this package. The
package implements parsing and tidying of the GEDCOM interchange format, which
is a file format specification rather than a statistical method.

## Notes on URLs

`urlchecker::url_check()` reports 404s for three badge URLs in README.md that
point at CRAN resources for this package
(`cran.r-project.org/package=tidygedcom` and the corresponding check-results
page). These resolve once the package is published and have been left as-is.

## Example data

The two GEDCOM files installed under `inst/extdata` are excerpts of a personal
genealogical research file shared by a co-investigator. They contain only
individuals who died before 1965; no living persons are included.

