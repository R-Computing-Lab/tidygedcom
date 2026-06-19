#' Initialize an Empty Individual Record
#'
#' @description Creates a named list with all GEDCOM initialized to NA_character_.
#'
#' @param all_var_names A character vector of variable names.
#' @return A named list representing an empty individual record.
#' @importFrom stats setNames
initializeRecord <- function(all_var_names) {
  stats::setNames(as.list(rep(NA_character_, length(all_var_names))), all_var_names)
}


#' Extract Information from Line
#'
#' @description
#' Extracts the relevant information from a GEDCOM line based on the specified type.
#' The function uses regular expressions to locate and return the desired data.
#'
#' @param line A character string representing a line from a GEDCOM file.
#' @param type A character string representing the type of information to extract.
#' @return A character string with the extracted information.
#' @keywords internal
#' @importFrom stringr str_extract str_squish
extractInfo <- function(line, type) {
  stringr::str_squish(stringr::str_extract(line, paste0("(?<=", type, " ).+")))
}

#' Combine Columns
#'
#' This function combines two columns, handling conflicts and merging non-conflicting data.
#' @param col1 The first column to combine.
#' @param col2 The second column to combine.
#' @return A list with the combined column and a flag indicating if the second column should be retained.
#' @keywords internal
#' @importFrom stringr str_to_lower
#'
# Helper function to check for conflicts and merge columns
combineColumns <- function(col1, col2) {
  col1_lower <- stringr::str_to_lower(col1)
  col2_lower <- stringr::str_to_lower(col2)
  conflicts <- !is.na(col1_lower) & !is.na(col2_lower) & col1_lower != col2_lower
  if (any(conflicts)) {
    warning("Columns have conflicting values. They were not merged.")
    list(combined = col1, retain_col2 = TRUE)
  } else {
    combined <- ifelse(is.na(col1), col2, col1)
    list(combined = combined, retain_col2 = FALSE)
  }
}

#' @title Parse Name Line
#'
#' @description Extracts full name information from a GEDCOM "NAME" line and updates the record accordingly.
#'
#' @param line A character string containing the name line.
#' @param record A named list representing the individual's record.
#' @return The updated record with parsed name information.
#' @keywords internal
#' @importFrom stringr str_extract str_squish str_replace
parseNameLine <- function(line, record) {
  record$name <- extractInfo(line, "NAME")
  record$name_given <- stringr::str_extract(record$name, ".*(?= /)")
  record$name_surn <- stringr::str_extract(record$name, "(?<=/).*(?=/)")
  record$name <- stringr::str_squish(stringr::str_replace(record$name, "/", " "))
  record
}

#' @title Extract GEDCOM Level
#'
#' @description Extracts the GEDCOM level (the leading integer) from a line of GEDCOM data.
#' This is used to determine the hierarchical structure of the data when parsing events and their sub-fields.
#' @param line A character string representing a line from a GEDCOM file.
#' @return An integer representing the GEDCOM level, or NA if no leading integer is found.
#' @keywords internal
#' @importFrom stringr str_extract

extractGedcomLevel <- function(line) {
  as.integer(stringr::str_extract(line, "^\\d+"))
}

#' @title Extract Information from Lines by Tag
#' @description
#' Given a set of lines (e.g., direct children of an event) and a
#' GEDCOM tag, this function searches for the first line that contains the tag as a whole word and extracts the relevant information using the `extractInfo()` function. If no matching line is found, it returns `NA_character_`.
#' @param lines A character vector of GEDCOM lines to search through.
#' @param tag A character string representing the GEDCOM tag to look for (e.g
#' "DATE", "PLAC", "CAUS").
#' @return A character string with the extracted information from the first matching line, or `NA_character_` if no matching line is found.
#' @keywords internal


extractInfoFromLines <- function(lines, tag) {
  pattern <- paste0("\\b", tag, "\\b")
  matches <- lines[grepl(pattern, lines)]
  if (length(matches) == 0L) {
    return(NA_character_)
  }
  extractInfo(matches[1L], tag)
}
