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


