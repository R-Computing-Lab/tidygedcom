# Description

This is a new submission that splits some functions and a dataset from the BGmisc package into a new package called tidygedcom. tidygedcom focuses on reading and parsing GEDCOM files, which are used to represent genealogical data. The package provides functions to read GEDCOM files, parse individual records, and convert the data into a tidy format for analysis. Unlike BGmisc, tidygedcom does not include functions for modeling pedigrees or other genealogical analyses. The package is designed to be fast and memory-efficient, making it suitable for working with large pedigrees as well as being compatible with the Tidyverse ecosystem. The package is intended for use by genealogists, researchers, and anyone interested in working with genealogical data in R.

Once this package is on CRAN, the BGmisc package will be updated to remove the functions that have been moved to tidygedcom. The BGmisc package will continue to provide functions for modeling pedigrees and other genealogical analyses, while tidygedcom will focus on reading and parsing GEDCOM files. We implemented a similar spinoff of plotting functions from BGmisc to ggpedigree, which is now on CRAN. Like ggpedigree, the tidygedcom package is intended to be a companion package to BGmisc, providing a streamlined and efficient way to read and parse GEDCOM files for genealogical analysis. 

# Requested revisions
- Used ::: in documentation, Solution: removed examples from internal functions, converted them to tests instead.
- Requested methods reference. Added citation to related paper that describes the data structure and methods used in the package Hunter et al. (2026) <doi:10.1007/s10519-026-10259-z>.

# Test Environments

1. Local OS: Windows 11 x64 (build 26220), R 4.6.1 (2026-06-24 ucrt)
2. **GitHub Actions**:  
    - [Link](https://github.com/R-Computing-Lab/tidygedcom/actions/runs/30318668817)
    - macOS (latest version) with the latest R release.
    - Windows (latest version) with the latest R release.
    - Ubuntu (latest version) with:
        - The development version of R.
        - The latest R release.

## R CMD check results


── R CMD check results ────────── tidygedcom 0.1.0 ────
Duration: 1m 0.2s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔



## Method references

There are no published references describing the methods in this package. The
package implements parsing and tidying of the GEDCOM interchange format, which
is a file format specification rather than a statistical method. More 
information on the GEDCOM format can be found in the GEDCOM 5.5.1 specification https://github.com/FamilySearch/GEDCOM. 

## Notes on URLs

The incoming-feasibility check reports one (possibly) invalid URL in README.md:

    https://cran.r-project.org/web/checks/check_results_tidygedcom.html

This is the target of the standard CRAN check-results badge. It 404s only
because the package is not yet published, and will resolve on acceptance, so it
has been left as-is. `urlchecker::url_check()` additionally flags the
`cran.r-project.org/package=tidygedcom` badge targets for the same reason. All
other URLs resolve.

## Example data

The two GEDCOM files installed under `inst/extdata` are excerpts of a personal
genealogical research file shared by a co-investigator. They contain only
individuals who died before 1965; no living persons are included.

