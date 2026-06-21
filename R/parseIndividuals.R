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


#' Split GEDCOM Lines into Individual Blocks
#'
#' @description
#' This function partitions the GEDCOM file (as a vector of lines) into a list of blocks,
#' where each block corresponds to a single individual starting with an "@ INDI" line.

#' @details Each block runs until the next "@ INDI" line or end-of-file.
#' Blocks are raw subsets of the file; no parsing occurs here.
#'
#' @param lines A character vector of lines from the GEDCOM file.
#' @param verbose Logical indicating whether to output progress messages.
#' @return A list of character vectors, each representing one individual.
#' @keywords internal
#'
splitIndividuals <- function(lines, verbose = FALSE) {
  indi_idx <- grep("@ INDI", lines)
  if (length(indi_idx) == 0) {
    return(list())
  }
  record_idx <- grep("@ (INDI|FAM|SOUR|REPO|OBJE|SUB[MN]|NOTE|_MTCAT)\\b| TRLR\\b", lines)

  blocks <- vector("list", length(indi_idx))
  for (i in seq_along(indi_idx)) {
    start <- indi_idx[i]
    next_record <- record_idx[record_idx > start]
    end <- if (length(next_record) > 0) next_record[1] - 1 else length(lines)
    blocks[[i]] <- lines[start:end]
  }
  if (verbose == TRUE) {
    message("Found ", length(blocks), " individual blocks")
    }
  blocks
}


#' Build Name-Piece Tag Mappings
#'
#' @description
#' Returns a list of tag-to-field mappings for GEDCOM name-piece tags
#' (\code{GIVN}, \code{NPFX}, \code{NICK}, \code{SURN}, \code{NSFX},
#' \code{_MARNM}). Build this once and pass it to
#' \code{parseIndividualBlock()} via the \code{mappings} argument.
#'
#' @return A list of mapping entries, each with \code{tag}, \code{field},
#'   and \code{mode} elements.
#' @keywords internal
make_name_piece_mappings <- function() {
  list(
    list(tag = "GIVN", field = "name_given_pieces", mode = "replace"),
    list(tag = "NPFX", field = "name_npfx", mode = "replace"),
    list(tag = "NICK", field = "name_nick", mode = "replace"),
    list(tag = "SURN", field = "name_surn_pieces", mode = "replace"),
    list(tag = "NSFX", field = "name_nsfx", mode = "replace"),
    list(tag = "_MARNM", field = "name_marriedsurn", mode = "replace")
  )
}

#' Build Attribute Tag Mappings
#'
#' @description
#' Returns a list of tag-to-field mappings for GEDCOM individual-attribute
#' tags (\code{SEX}, \code{CAST}, \code{DSCR}, \code{EDUC}, \code{IDNO},
#' \code{NATI}, \code{NCHI}, \code{NMR}, \code{OCCU}, \code{PROP},
#' \code{RELI}, \code{RESI}, \code{SSN}, \code{TITL}). Build this once and
#' pass it to \code{parseIndividualBlock()} via the \code{mappings} argument.
#'
#' @return A list of mapping entries, each with \code{tag}, \code{field},
#'   and \code{mode} elements.
#' @keywords internal
make_attribute_mappings <- function() {
  list(
    list(tag = "SEX", field = "sex", mode = "replace"),
    list(tag = "CAST", field = "attribute_caste", mode = "replace"),
    list(tag = "DSCR", field = "attribute_description", mode = "replace"),
    list(tag = "EDUC", field = "attribute_education", mode = "replace"),
    list(tag = "IDNO", field = "attribute_idnumber", mode = "replace"),
    list(tag = "NATI", field = "attribute_nationality", mode = "replace"),
    list(tag = "NCHI", field = "attribute_children", mode = "replace"),
    list(tag = "NMR", field = "attribute_marriages", mode = "replace"),
    list(tag = "OCCU", field = "attribute_occupation", mode = "replace"),
    list(tag = "PROP", field = "attribute_property", mode = "replace"),
    list(tag = "RELI", field = "attribute_religion", mode = "replace"),
    list(tag = "RESI", field = "attribute_residence", mode = "append"),
    list(tag = "SSN", field = "attribute_ssn", mode = "replace"),
    list(tag = "TITL", field = "attribute_title", mode = "replace")
  )
}

#' Build Relationship Tag Mappings
#'
#' @description
#' Returns a list of tag-to-field mappings for GEDCOM family-relationship
#' tags (\code{FAMC}, \code{FAMS}). Each entry includes a custom extractor
#' that pulls the numeric family ID from the cross-reference pointer. Build
#' this once and pass it to \code{parseIndividualBlock()} via the
#' \code{mappings} argument.
#'
#' @return A list of mapping entries, each with \code{tag}, \code{field},
#'   \code{mode}, and \code{extractor} elements.
#' @keywords internal
#' @importFrom stringr str_extract
make_relationship_mappings <- function() {
  list(
    list(
      tag = "FAMC", field = "FAMC", mode = "append",
      extractor = function(x) stringr::str_extract(x, "(?<=@.)\\d*(?=@)")
    ),
    list(
      tag = "FAMS", field = "FAMS", mode = "append",
      extractor = function(x) stringr::str_extract(x, "(?<=@.)\\d*(?=@)")
    )
  )
}


#' Parse a GEDCOM Individual Block
#'
#' @description Processes a block of GEDCOM lines corresponding to a single individual.
#'
#' @param block A character vector containing the GEDCOM lines for one individual.
#' @param pattern_rows A list with counts of lines matching specific GEDCOM tags.
#' @param all_var_names A character vector of variable names.
#' @param mappings A named list of pre-built tag mappings as returned by
#'   \code{make_event_fields()}, \code{make_name_piece_mappings()},
#'   \code{make_attribute_mappings()}, and \code{make_relationship_mappings()}.
#' @param verbose Logical indicating whether to print progress messages.
#' @return A named list representing the parsed record for the individual, or NULL if no ID is found.
#' @keywords internal
#' @importFrom stringr str_extract str_squish str_replace
parseIndividualBlock <- function(block,
                                 pattern_rows,
                                 all_var_names,
                                 mappings, verbose = FALSE) {
  record <- initializeRecord(all_var_names)
  n_lines <- length(block)

  # Loop through the block by index so that we can look ahead for event details.
  i <- 1
  while (i <= n_lines) {
    line <- block[i]

    # Process individual identifier (e.g., "@ INDI ...")
    if (grepl("@ INDI", line)) {
      record$personID <- stringr::str_extract(line, "(?<=@.)\\d*(?=@)")
      i <- i + 1
      next
    }

    # Special processing for full name using " NAME" tag.
    if (grepl(" NAME", line) && pattern_rows$num_name_rows > 0) {
      record <- parseNameLine(line, record)
      i <- i + 1
      next
    }

    # Process life events by consuming the sub-block of child lines.
    if (grepl(" BIRT", line) && pattern_rows$num_birt_rows > 0) {
      record <- processEventLine("birth", block, i, record, pattern_rows, mappings$event_fields)
      i <- i + 1 # Skip further processing of this line.
      next
    }
    if (grepl("\\bCHR\\b", line) && pattern_rows$num_chr_rows > 0) {
      record <- processEventLine("chr", block, i, record, pattern_rows, mappings$event_fields)
      i <- i + 1 # Skip further processing of this line.
      next
    }
    if (grepl(" DEAT", line) && pattern_rows$num_deat_rows > 0) {
      record <- processEventLine("death", block, i, record, pattern_rows, mappings$event_fields)
      i <- i + 1 # Skip further processing of this line.
      next
    }
    if (grepl("\\bBURI\\b", line) && pattern_rows$num_buri_rows > 0) {
      record <- processEventLine("burial", block, i, record, pattern_rows, mappings$event_fields)
      i <- i + 1 # Skip further processing of this line.
      next
    }

    # Process name-piece, attribute, and relationship tags via shared dispatcher.
    out <- applyTagMappings(line, record, pattern_rows, mappings$name_piece_mappings)
    if (out$matched) {
      record <- out$record
      i <- i + 1
      next
    }

    out <- applyTagMappings(line, record, pattern_rows, mappings$attribute_mappings)
    if (out$matched) {
      record <- out$record
      i <- i + 1
      next
    }

    out <- applyTagMappings(line, record, pattern_rows, mappings$relationship_mappings)
    if (out$matched) {
      record <- out$record
      i <- i + 1
      next
    }

    i <- i + 1
  }

  # If the record has no ID, return NULL.
  if (is.na(record$personID)) {
    return(NULL)
  }
  record
}


#' Apply Tag Mappings to a Line
#'
#' @description Iterates over a list of tag mappings and, if a tag matches the line, updates the record.
#' Stops after the first match.
#'
#' @param line A character string from the GEDCOM file.
#' @param record A named list representing the individual's record.
#' @param pattern_rows A list with GEDCOM tag counts.
#' @param tag_mappings A list of lists. Each sublist should define:
#'   - \code{tag}: the GEDCOM tag,
#'   - \code{field}: the record field to update,
#'   - \code{mode}: either "replace" or "append",
#'   - \code{extractor}: (optional) a custom extraction function.
#' @return A list with the updated record (\code{record}) and a logical flag (\code{matched}).
#'
applyTagMappings <- function(line, record, pattern_rows, tag_mappings) {
  for (mapping in tag_mappings) {
    extractor <- if (is.null(mapping$extractor)) NULL else mapping$extractor
    result <- processTag(mapping$tag,
      mapping$field,
      pattern_rows, line, record,
      extractor = extractor,
      mode = mapping$mode
    )
    record <- result$vars
    if (result$matched) {
      return(list(record = record, matched = TRUE))
    }
  }
  list(record = record, matched = FALSE)
}



#' Count GEDCOM Pattern Rows
#'
#' @description
#' Counts the number of lines in a file (passed as a data frame with column "X1")
#' that match various GEDCOM patterns. Returns a list with counts for each pattern.
#'
#' @param file A data frame with a column \code{X1} containing GEDCOM lines.
#' @return A list with counts of specific GEDCOM tag occurrences.
countPatternRows <- function(file) {
  x <- file$X1
  pattern_counts <- vapply(
    c(
      "@ INDI", " NAME", " GIVN", " NPFX", " NICK", " SURN", " NSFX", " _MARNM",
      " BIRT", " CHR", " DEAT", " BURI", " SEX", " CAST", " DSCR", " EDUC",
      " IDNO", " NATI", " NCHI", " NMR", " OCCU", " PROP", " RELI", " RESI",
      " SSN", " TITL", " FAMC", " FAMS", " PLAC", " LATI", " LONG", " DATE", " CAUS"
    ),
    function(pat) sum(grepl(pat, x, fixed = TRUE)),
    integer(1L)
  )
  num_rows <- list(
    num_indi_rows = pattern_counts["@ INDI"],
    num_name_rows = pattern_counts[" NAME"],
    num_givn_rows = pattern_counts[" GIVN"],
    num_npfx_rows = pattern_counts[" NPFX"],
    num_nick_rows = pattern_counts[" NICK"],
    num_surn_rows = pattern_counts[" SURN"],
    num_nsfx_rows = pattern_counts[" NSFX"],
    num_marnm_rows = pattern_counts[" _MARNM"],
    num_birt_rows = pattern_counts[" BIRT"],
    num_chr_rows = pattern_counts[" CHR"],
    num_deat_rows = pattern_counts[" DEAT"],
    num_buri_rows = pattern_counts[" BURI"],
    num_sex_rows = pattern_counts[" SEX"],
    num_cast_rows = pattern_counts[" CAST"],
    num_dscr_rows = pattern_counts[" DSCR"],
    num_educ_rows = pattern_counts[" EDUC"],
    num_idno_rows = pattern_counts[" IDNO"],
    num_nati_rows = pattern_counts[" NATI"],
    num_nchi_rows = pattern_counts[" NCHI"],
    num_nmr_rows = pattern_counts[" NMR"],
    num_occu_rows = pattern_counts[" OCCU"],
    num_prop_rows = pattern_counts[" PROP"],
    num_reli_rows = pattern_counts[" RELI"],
    num_resi_rows = pattern_counts[" RESI"],
    num_ssn_rows = pattern_counts[" SSN"],
    num_titl_rows = pattern_counts[" TITL"],
    num_famc_rows = pattern_counts[" FAMC"],
    num_fams_rows = pattern_counts[" FAMS"],
    num_plac_rows = pattern_counts[" PLAC"],
    num_lati_rows = pattern_counts[" LATI"],
    num_long_rows = pattern_counts[" LONG"],
    num_date_rows = pattern_counts[" DATE"],
    num_caus_rows = pattern_counts[" CAUS"]
  )
  num_rows
}

#' Process a GEDCOM Tag
#'
#' @description
#' Extracts and assigns a value to a specified field in `vars` if the pattern is present.
#' Returns both the updated variable list and a flag indicating whether the tag was matched.
#'
#' @param tag The GEDCOM tag (e.g., "SEX", "CAST", etc.).
#' @param field_name The name of the variable to assign to in `vars`.
#' @param pattern_rows Output from `countPatternRows()`.
#' @param line The GEDCOM line to parse.
#' @param vars The current list of variables to update.
#' @return A list with updated `vars` and a `matched` flag.
#' @keywords internal
processTag <- function(tag,
                       field_name,
                       pattern_rows,
                       line,
                       vars,
                       extractor = NULL,
                       mode = "replace") {
  count_name <- paste0(
    "num_", # normalize leading underscores
    tolower(gsub("^_", "", tag)), "_rows"
  )
  matched <- FALSE
  if (!is.null(pattern_rows[[count_name]]) &&
    pattern_rows[[count_name]] > 0 &&
    grepl(paste0(" ", tag), line)) {
    value <- if (is.null(extractor)) {
      extractInfo(line, tag)
    } else {
      extractor(line)
    }
    if (mode == "append" && !is.na(vars[[field_name]])) {
      vars[[field_name]] <- paste0(vars[[field_name]], ", ", value)
    } else {
      vars[[field_name]] <- value
    }
    matched <- TRUE
  }
  list(vars = vars, matched = matched)
}
