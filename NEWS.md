# tidygedcom

## Development version


* Optimized gedcom reader, com2links for speed and memory usage, with a focus on large pedigrees
* Fixed bug in gedcom reader that resulted in document records being added to the final person in the pedigree
* Added more unit tests for gedcom reader and data parser
* several improvements to the GEDCOM parsing functionality, focusing on more robust and flexible event parsing, better support for different GEDCOM versions, and enhanced usability.


# tidygedcom 0.1
* Splitting gedcom reader off from BGmisc. See history of those files in BGmisc:
	- https://github.com/R-Computing-Lab/BGmisc/commits/main/R/readGedcom.R
	- https://github.com/R-Computing-Lab/BGmisc/commits/main/R/readGedcomlegacy.R
	- https://github.com/R-Computing-Lab/BGmisc/commits/main/R/readWikifamilytree.R
* Added a `NEWS.md` file to track changes to the package.
* Initial version launched
