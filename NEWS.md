# tidygedcom 0.1.0

* Initial CRAN submission.

### Date handling

* `readGedcom(parse_dates = TRUE)` now retains dates that are precise only to the month or the year. Previously these became `NA`, which discarded most of the dates in a typical historical pedigree. Partial dates are completed with the midpoint of the known interval (the 15th of a known month, 15 June for a known year); set the new `impute_partial_dates = FALSE` to restore the stricter behaviour and keep only dates that specify a day.
* Date qualifiers written with a trailing period (`Abt.`, `Aft.`), as Ancestry.com exports them, are now stripped. Previously only the specification's unpunctuated forms (`ABT`, `AFT`) were recognized, so `"Aft. Oct 1896"` failed to parse.
* Extracted `stripDateQualifiers()` and `imputePartialDates()` as documented internal helpers.

### Bug fixes

* `readGedcom()` no longer leaves a stray `/` in the `name` column when a name suffix follows the surname (e.g. `1 NAME William Pitt /Waugh/ Jr` parsed as `William Pitt Waugh/ Jr`). Both surname delimiters are now removed.
* `readGedcom()` no longer errors with "missing value where TRUE/FALSE needed" when a spouse record has no `SEX` line. Individuals with unknown sex are skipped during parent mapping rather than compared.

### Documentation

* The "Getting Started" vignette now walks through exporting a GEDCOM file from a genealogy service, including the instability of person IDs across exports and a note on the privacy implications of sharing an export containing living people.

### Example data

* Added two example GEDCOM files, installed under `inst/extdata`, drawn from the W. Henderson Waugh Family Tree and covering eight individuals (all deceased) across four families:
  * `waugh.ged` — a clean excerpt for documentation examples.
  * `waugh_messy.ged` — the same individuals retaining source-export defects (conflicting duplicate `BIRT` blocks, competing `PLAC` lines, an uncertain surname, a missing `SEX` value, and an individual with no birth record).

### Internal refactoring

* Reorganized R source files for clearer separation of concerns: parsing logic split across `parseIndividuals.R`, `parseEvents.R`, `parseLines.R`, `parseFamily.R`, and `postProcessGedcom.R`; `readGedcom.R` is now a slim orchestration entry point only.
* Extracted four constructor functions (`make_event_fields()`, `make_name_piece_mappings()`, `make_attribute_mappings()`, `make_relationship_mappings()`) that build static tag-mapping tables. These are called once in `readGedcom()` before the per-individual `lapply`, and passed in as a `mappings` argument to `parseIndividualBlock()`, avoiding redundant reconstruction on every block.
* Replaced the `processEventLine()` if/else chain with a data-driven dispatch over the `event_fields` lookup table, reducing the cost of adding new event types to a single table entry.
* Pre-allocated the `blocks` list in `splitIndividuals()` (`vector("list", n)`) rather than growing it element-by-element.
* Split the monolithic test file into focused files: `test-parseEvents.R`, `test-convertCoords.R`, `test-postProcessGedcom.R`, and `test-readGedcom.R`.
* Added Roxygen documentation for all new internal functions.

### Earlier development changes

* Optimized gedcom reader for speed and memory usage, with a focus on large pedigrees.
* Fixed bug in gedcom reader that resulted in document records being added to the final person in the pedigree.
* Added more unit tests for gedcom reader and data parser.
* Several improvements to GEDCOM parsing, focusing on more robust and flexible event parsing, better support for different GEDCOM versions, and enhanced usability.


### Origin

* Split the GEDCOM reader off from BGmisc. See history of those files in BGmisc:
	- https://github.com/R-Computing-Lab/BGmisc/commits/main/R/readGedcom.R
	- https://github.com/R-Computing-Lab/BGmisc/commits/main/R/readGedcomlegacy.R
	- https://github.com/R-Computing-Lab/BGmisc/commits/main/R/readWikifamilytree.R
* Added a `NEWS.md` file to track changes to the package.
* Initial version launched
