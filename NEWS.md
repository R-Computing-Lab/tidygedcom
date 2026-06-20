# tidygedcom

## Development version

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


# tidygedcom 0.1
* Splitting gedcom reader off from BGmisc. See history of those files in BGmisc:
	- https://github.com/R-Computing-Lab/BGmisc/commits/main/R/readGedcom.R
	- https://github.com/R-Computing-Lab/BGmisc/commits/main/R/readGedcomlegacy.R
	- https://github.com/R-Computing-Lab/BGmisc/commits/main/R/readWikifamilytree.R
* Added a `NEWS.md` file to track changes to the package.
* Initial version launched
