#' @title Extract Event Sub-Block
#' @description
#' Given a block of GEDCOM lines and a starting index corresponding to an event tag (e.g., "BIRT" or "DEAT"), this function extracts the sub-block of lines that are children of that event. It uses the GEDCOM level structure to determine which lines belong to the event's sub-block, returning all lines until it encounters a line with a level less than or equal to the event's level.
#' @param block A character vector of GEDCOM lines representing an individual's record.
#' @param start_idx An integer index indicating the line in the block where the event tag is located.
#' @return A character vector containing the lines that are part of the event's sub-block, or an empty character vector if there are no child lines.
#' @keywords internal


extractEventSubBlock <- function(block, start_idx) {
  event_level <- extractGedcomLevel(block[start_idx])
  n <- length(block)
  # start_idx is always within bounds because it comes from a bounded loop in the caller,
  # but guard defensively to avoid the descending-sequence pitfall of R's : operator.
  if (start_idx >= n) {
    return(character(0))
  }
  end_idx <- start_idx
  for (j in (start_idx + 1L):n) {
    lvl <- extractGedcomLevel(block[j])
    if (is.na(lvl)) next
    if (lvl <= event_level) break
    end_idx <- j
  }
  if (end_idx == start_idx) {
    return(character(0))
  }
  block[(start_idx + 1L):end_idx]
}


#' Process Event Lines (Birth or Death)
#'
#' @description Extracts event details (e.g., date, place, cause, latitude, longitude) from a block of GEDCOM lines.
#' Uses level-aware sub-block parsing so fields are looked up by tag name rather than fixed offsets.
#' @param event A character string indicating the event type ("birth" or "death").
#' @param block A character vector of GEDCOM lines.
#' @param i The current line index where the event tag is found.
#' @param record A named list representing the individual's record.
#' @param pattern_rows A list with counts of GEDCOM tag occurrences.
#' @return The updated record with parsed event information.
processEventLine <- function(event, block, i, record, pattern_rows) {
  sub_block <- extractEventSubBlock(block, i)
  if (length(sub_block) == 0L) {
    return(record)
  }

  event_level <- extractGedcomLevel(block[i])
  direct_children <- sub_block[
    vapply(sub_block, extractGedcomLevel, integer(1L)) == event_level + 1L
  ]

  if (event == "birth") {
    record$birth_date <- extractInfoFromLines(direct_children, "DATE")
    record$birth_place <- extractInfoFromLines(direct_children, "PLAC")
    record$birth_lat <- extractCoordFromSubBlock(sub_block, "LATI")
    record$birth_long <- extractCoordFromSubBlock(sub_block, "LONG")
  } else if (event == "chr") {
    record$chr_date <- extractInfoFromLines(direct_children, "DATE")
    record$chr_place <- extractInfoFromLines(direct_children, "PLAC")
  } else if (event == "death") {
    record$death_date <- extractInfoFromLines(direct_children, "DATE")
    record$death_place <- extractInfoFromLines(direct_children, "PLAC")
    record$death_caus <- extractInfoFromLines(direct_children, "CAUS")
    record$death_lat <- extractCoordFromSubBlock(sub_block, "LATI")
    record$death_long <- extractCoordFromSubBlock(sub_block, "LONG")
  } else if (event == "burial") {
    record$burial_date <- extractInfoFromLines(direct_children, "DATE")
    record$burial_place <- extractInfoFromLines(direct_children, "PLAC")
    record$burial_lat <- extractCoordFromSubBlock(sub_block, "LATI")
    record$burial_long <- extractCoordFromSubBlock(sub_block, "LONG")
  }
  record
}

#' @title Extract Coordinate from Event Sub-Block
#' @description
#' Given a sub-block of GEDCOM lines corresponding to an event (e.g., birth
#' or death) and a coordinate tag ("LATI" or "LONG"), this function searches all lines in the sub-block for the first occurrence of the tag as a whole word. This approach allows it to find coordinates regardless of whether they are direct children of the event, nested under a "PLAC" structure, or nested under a "MAP" structure within "PLAC". If a matching line is found, it extracts the coordinate information using the `extractInfo()` function; otherwise, it returns `NA_character_`.
#' @param sub_block A character vector of GEDCOM lines representing the sub-block of an
#' event (e.g., birth or death) from which to extract the coordinate.
#' @param tag A character string representing the coordinate tag to look for ("LATI" or "LONG").
#' @return A character string with the extracted coordinate information from the first matching
#' line, or `NA_character_` if no matching line is found.
#' @keywords internal
#'

extractCoordFromSubBlock <- function(sub_block, tag) {
  # Searches all levels of the sub-block so it handles:
  #   GEDCOM 5.5.x: LATI/LONG as direct children of the event
  #   GEDCOM 5.5.x standard: LATI/LONG under PLAC (level+2)
  #   GEDCOM 7.x: LATI/LONG under MAP under PLAC (level+3)
  pattern <- paste0("\\b", tag, "\\b")
  matches <- sub_block[grepl(pattern, sub_block)]
  if (length(matches) == 0L) {
    return(NA_character_)
  }
  extractInfo(matches[1L], tag)
}
