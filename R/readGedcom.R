#' Read a GEDCOM File
#'
#' Ingests a GEDCOM genealogy file, identifies individual records, and parses
#' person-level identifiers, names, life events, attributes, and family
#' relationships into a structured data frame. Optional post-processing can infer
#' parental IDs from family relationships, reconcile redundant name fields, and
#' remove uninformative columns from the parsed output.
#'
#' @details
#' `readGedcom()` is a line-oriented parser tuned to common GEDCOM 5.5 and 5.5.1
#' structures. Individual records are identified from blocks that begin with an
#' `@ INDI` line. Each individual block is passed to an internal parser that uses
#' simple GEDCOM tag pattern matches to extract identifiers, names, life events,
#' attributes, and family relationships.
#'
#' Name information is parsed primarily from the GEDCOM `NAME` tag, which often
#' encodes given names and surnames using slash-delimited surname notation, such
#' as `NAME John /Smith/`. The parser extracts the given name, surname, and a
#' cleaned full name. Additional name components are parsed when present,
#' including name prefix, name suffix, nickname, and married surname.
#'
#' Birth and death events are recognized from `BIRT` and `DEAT` tags. Event
#' details are parsed by collecting all child lines whose GEDCOM level equals
#' the event level plus one (direct children), then looking up sub-fields by
#' tag name. `DATE`, `PLAC`, and `CAUS` are matched as direct children of the
#' event. Coordinates (`LATI` and `LONG`) are searched across all descendant
#' lines, which allows them to be located whether they appear as direct children
#' (common in some GEDCOM 5.5.x exporters), under `PLAC` (standard GEDCOM
#' 5.5.1), or under a `MAP` substructure under `PLAC` (GEDCOM 7.x). Missing
#' sub-fields leave the corresponding output columns as `NA`.
#'
#' Attribute tags such as `OCCU`, `EDUC`, `RELI`, `CAST`, `NCHI`, `NMR`, `NATI`,
#' `RESI`, `PROP`, `SSN`, `TITL`, `DSCR`, and `IDNO` are parsed directly into
#' dedicated columns prefixed with `attribute_`.
#'
#' Family relationships are parsed from `FAMC` and `FAMS` tags. `FAMC` identifies
#' the family in which an individual is a child, and `FAMS` identifies families
#' in which an individual is a spouse. These raw family identifiers are retained
#' in the parsed output unless removed during post-processing. When
#' `add_parents = TRUE`, they are also used to infer `momID` and `dadID`.
#'
#' If `post_process = TRUE`, `readGedcom()` applies optional cleanup steps
#' controlled by `add_parents`, `combine_cols`, `remove_empty_cols`, and
#' `skinny`. These steps can infer parent IDs, collapse redundant name fields,
#' remove columns that are entirely missing, and drop raw family relationship
#' columns for a slimmer output.
#'
#' @param file_path Character string. Path to the GEDCOM file.
#' @param verbose Logical. If `TRUE`, print progress messages.
#' @param remove_empty_cols Logical. If `TRUE`, drop columns that are entirely
#'   `NA` during post-processing.
#' @param skinny Logical. If `TRUE`, return a slimmer data frame by dropping
#'   `FAMC`, `FAMS`, and columns that are entirely `NA` during post-processing.
#' @param update_rate Numeric. Intended rate at which progress messages should
#'   be printed. Currently unused.
#' @param post_process Logical. If `TRUE`, apply post-processing steps controlled
#'   by `add_parents`, `combine_cols`, `remove_empty_cols`, `skinny`, and `parse_dates`.
#' @param remove_empty_cols Logical indicating whether to remove columns that are entirely missing.
#' @param combine_cols Logical. If `TRUE`, combine redundant name columns, such
#'   as `name_given` with `name_given_pieces` and `name_surn` with
#'   `name_surn_pieces`, when their values do not conflict.
#' @param add_parents Logical. If `TRUE`, infer `momID` and `dadID` from `FAMC`
#'   and `FAMS` mappings during post-processing.
#' @param parse_dates Logical. If `TRUE`, attempt to parse date columns (e.g., `birth_date`, `death_date`) into Date objects, after removing common GEDCOM date qualifiers like "ABT", "BEF", and "AFT".
#' @param clean_names Logical indicating whether to clean name columns by removing trailing slashes and squishing whitespace.
#' @param ... Additional arguments. Currently unused.
#' @return A data frame containing information about individuals, with the following potential columns:
#' \describe{
#'   \item{personID}{Individual ID parsed from the `@ INDI` line.}
#'   \item{momID}{ID of the individual's mother, if inferred.}
#'   \item{dadID}{ID of the individual's father, if inferred.}
#'   \item{sex}{Sex of the individual.}
#'   \item{name}{Cleaned full name of the individual.}
#'   \item{name_given}{Given name parsed from the `NAME` tag.}
#'   \item{name_given_pieces}{Given name parsed from a separate `GIVN` tag, if present.}
#'   \item{name_surn}{Surname parsed from the `NAME` tag.}
#'   \item{name_surn_pieces}{Surname parsed from a separate `SURN` tag, if present.}
#'   \item{name_marriedsurn}{Married surname parsed from `_MARNM`, if present.}
#'   \item{name_nick}{Nickname parsed from `NICK`, if present.}
#'   \item{name_npfx}{Name prefix parsed from `NPFX`, if present.}
#'   \item{name_nsfx}{Name suffix parsed from `NSFX`, if present.}
#'   \item{birth_date}{Birth date of the individual.}
#'   \item{birth_lat}{Latitude of the birthplace.}
#'   \item{birth_long}{Longitude of the birthplace.}
#'   \item{birth_place}{Birthplace of the individual.}
#'   \item{chr_date}{Christening date of the individual (`CHR` tag).}
#'   \item{chr_place}{Christening place of the individual.}
#'   \item{death_caus}{Cause of death.}
#'   \item{death_date}{Death date of the individual.}
#'   \item{death_lat}{Latitude of the place of death.}
#'   \item{death_long}{Longitude of the place of death.}
#'   \item{death_place}{Place of death of the individual.}
#'   \item{burial_date}{Burial date of the individual (`BURI` tag).}
#'   \item{burial_lat}{Latitude of the burial place.}
#'   \item{burial_long}{Longitude of the burial place.}
#'   \item{burial_place}{Burial place of the individual.}
#'   \item{attribute_caste}{Caste of the individual.}
#'   \item{attribute_children}{Number of children of the individual.}
#'   \item{attribute_description}{Description of the individual.}
#'   \item{attribute_education}{Education of the individual.}
#'   \item{attribute_idnumber}{Identification number of the individual.}
#'   \item{attribute_marriages}{Number of marriages of the individual.}
#'   \item{attribute_nationality}{Nationality of the individual.}
#'   \item{attribute_occupation}{Occupation of the individual.}
#'   \item{attribute_property}{Property owned by the individual.}
#'   \item{attribute_religion}{Religion of the individual.}
#'   \item{attribute_residence}{Residence of the individual.}
#'   \item{attribute_ssn}{Social Security number of the individual.}
#'   \item{attribute_title}{Title of the individual.}
#'   \item{FAMC}{ID or IDs of the family in which the individual is a child.}
#'   \item{FAMS}{ID or IDs of families in which the individual is a spouse.}
#' }
#'
#' If no individual records are found, the function returns `NULL` with a
#' warning.
#' @export


readGedcom <- function(file_path,
                       verbose = FALSE,
                       post_process = TRUE,
                       add_parents = TRUE,
                       remove_empty_cols = TRUE,
                       combine_cols = TRUE,
                       skinny = FALSE,
                       parse_dates = FALSE,
                       clean_names = TRUE,
                       update_rate = 1000,
                       ...) {
  # Ensure the file exists and read all lines.
  if (!file.exists(file_path)) {
    stop("File does not exist: ", file_path)
  }
  if (verbose == TRUE) message("Reading file: ", file_path)
  lines <- readLines(file_path)
  gedcom_version <- detectGedcomVersion(lines)
  if (verbose) message("Detected GEDCOM version: ", gedcom_version)
  total_lines <- length(lines)
  if (verbose == TRUE) message("File is ", total_lines, " lines long")

  # Count pattern occurrences (pattern_rows remains used in subfunctions)
  pattern_rows <- countPatternRows(data.frame(X1 = lines))

  # List of variables to initialize
  all_var_names <- unlist(list(
    identifiers = c("personID", "momID", "dadID"),
    names = c(
      "name", "name_given", "name_given_pieces",
      "name_surn", "name_surn_pieces", "name_marriedsurn",
      "name_nick", "name_npfx", "name_nsfx"
    ),
    sex = c("sex"),
    birth = c("birth_date", "birth_lat", "birth_long", "birth_place"),
    chr = c("chr_date", "chr_place"),
    death = c("death_caus", "death_date", "death_lat", "death_long", "death_place"),
    burial = c("burial_date", "burial_lat", "burial_long", "burial_place"),
    attributes = c(
      "attribute_caste", "attribute_children",
      "attribute_description", "attribute_education",
      "attribute_idnumber", "attribute_marriages",
      "attribute_nationality", "attribute_occupation",
      "attribute_property", "attribute_religion",
      "attribute_residence", "attribute_ssn",
      "attribute_title"
    ),
    relationships = c("FAMC", "FAMS")
  ), use.names = FALSE)

  # Split the file into blocks; each block corresponds to one individual.
  blocks <- splitIndividuals(lines, verbose)

  # Parse each individual block into a record (a named list)
  records <- lapply(blocks, parseIndividualBlock,
    pattern_rows = pattern_rows,
    all_var_names = all_var_names, verbose = verbose
  )

  # Remove any NULLs (if a block did not contain an individual id)
  records <- Filter(Negate(is.null), records)

  if (length(records) == 0) {
    # Returns NULL without a gedcom_version attribute; callers should check is.null() first.
    warning("No people found in file")
    return(NULL)
  }

  # Convert the list of records to a data frame.
  df_temp <- do.call(rbind, lapply(records, function(rec) {
    as.data.frame(rec, stringsAsFactors = FALSE)
  }))

  if (verbose == TRUE) message("File has ", nrow(df_temp), " people")

  # Run post-processing if requested.
  if (post_process == TRUE) {
    if (verbose == TRUE) message("Post-processing data frame")
    df_temp <- postProcessGedcom(
      df_temp = df_temp,
      remove_empty_cols = remove_empty_cols,
      combine_cols = combine_cols,
      parse_dates = parse_dates,
      add_parents = add_parents,
      clean_names = clean_names,
      skinny = skinny,
      verbose = verbose
    )
  }

  attr(df_temp, "gedcom_version") <- gedcom_version
  df_temp
}

# --- SUBFUNCTIONS ---
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


  blocks <- list()
  for (i in seq_along(indi_idx)) {
    start <- indi_idx[i]

    next_record <- record_idx[record_idx > start]

    end <- if (length(next_record) > 0) {
      next_record[1] - 1
    } else {
      length(lines)
    }
    block <- lines[start:end]
    blocks[[length(blocks) + 1]] <- block
  }
  if (verbose == TRUE) message("Found ", length(blocks), " individual blocks")
  blocks
}


#' Parse a GEDCOM Individual Block
#'
#' @description Processes a block of GEDCOM lines corresponding to a single individual.
#'
#' @param block A character vector containing the GEDCOM lines for one individual.
#' @param pattern_rows A list with counts of lines matching specific GEDCOM tags.
#' @param all_var_names A character vector of variable names.
#' @param verbose Logical indicating whether to print progress messages.
#' @return A named list representing the parsed record for the individual, or NULL if no ID is found.
#' @keywords internal
#' @importFrom stringr str_extract str_squish str_replace
parseIndividualBlock <- function(block, pattern_rows, all_var_names, verbose = FALSE) {
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

    # Process birth and death events by consuming multiple lines.
    if (grepl(" BIRT", line) && pattern_rows$num_birt_rows > 0) {
      record <- processEventLine("birth", block, i, record, pattern_rows)
      i <- i + 1 # Skip further processing of this line.
      next
    }
    if (grepl("\\bCHR\\b", line) && pattern_rows$num_chr_rows > 0) {
      record <- processEventLine("chr", block, i, record, pattern_rows)
      i <- i + 1
      next
    }
    if (grepl(" DEAT", line) && pattern_rows$num_deat_rows > 0) {
      record <- processEventLine("death", block, i, record, pattern_rows)
      i <- i + 1
      next
    }
    if (grepl("\\bBURI\\b", line) && pattern_rows$num_buri_rows > 0) {
      record <- processEventLine("burial", block, i, record, pattern_rows)
      i <- i + 1
      next
    }

    # Process other tags using common mappings.
    # Define mappings for name pieces (if not handled by NAME tag).
    name_piece_mappings <- list(
      list(tag = "GIVN", field = "name_given_pieces", mode = "replace"),
      list(tag = "NPFX", field = "name_npfx", mode = "replace"),
      list(tag = "NICK", field = "name_nick", mode = "replace"),
      list(tag = "SURN", field = "name_surn_pieces", mode = "replace"),
      list(tag = "NSFX", field = "name_nsfx", mode = "replace"),
      list(tag = "_MARNM", field = "name_marriedsurn", mode = "replace")
    )
    out <- applyTagMappings(line, record, pattern_rows, name_piece_mappings)
    if (out$matched) {
      record <- out$record
      i <- i + 1
      next
    }

    # Process attribute tags.
    attribute_mappings <- list(
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
    out <- applyTagMappings(line, record, pattern_rows, attribute_mappings)
    if (out$matched) {
      record <- out$record
      i <- i + 1
      next
    }

    # Process relationship tags, using a custom extractor.
    relationship_mappings <- list(
      list(
        tag = "FAMC", field = "FAMC", mode = "append",
        extractor = function(x) stringr::str_extract(x, "(?<=@.)\\d*(?=@)")
      ),
      list(
        tag = "FAMS", field = "FAMS", mode = "append",
        extractor = function(x) stringr::str_extract(x, "(?<=@.)\\d*(?=@)")
      )
    )
    out <- applyTagMappings(
      line, record,
      pattern_rows,
      relationship_mappings
    )
    if (out$matched) {
      record <- out$record
      i <- i + 1
      next
    }

    # Optionally print progress for long records.
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



# --- Exported Aliases ---
#' @rdname readGedcom
#' @export
readGed <- readGedcom
#' @rdname readGedcom
#' @export
readgedcom <- readGedcom







#' Detect GEDCOM Version from File Lines
#'
#' @param lines Character vector of lines from a GEDCOM file.
#' @return A string such as `"5.5.1"`, `"7.0"`, or `"unknown"`.
#' @keywords internal
detectGedcomVersion <- function(lines) {
  head_idx <- which(grepl("^0 HEAD\\b", lines))[1L]
  if (is.na(head_idx)) {
    return("unknown")
  }

  # End of HEAD is the next level-0 record
  if (head_idx >= length(lines)) {
    return("unknown")
  }
  next_l0 <- which(grepl("^0 ", lines[(head_idx + 1L):length(lines)]))[1L]
  head_end <- if (is.na(next_l0)) length(lines) else head_idx + next_l0 - 1L
  head_block <- lines[head_idx:head_end]

  gedc_idx <- which(grepl("^1 GEDC\\b", head_block))[1L]
  if (is.na(gedc_idx)) {
    return("unknown")
  }

  # Guard: if GEDC is the last line of HEAD, there is no VERS to look ahead to
  if (gedc_idx >= length(head_block)) {
    return("unknown")
  }

  # Look ahead within HEAD block for the VERS line under GEDC
  lookahead <- head_block[seq(gedc_idx + 1L, min(gedc_idx + 5L, length(head_block)))]
  vers_line <- lookahead[grepl("^2 VERS\\b", lookahead)][1L]
  if (is.na(vers_line)) {
    return("unknown")
  }

  val <- extractInfo(vers_line, "VERS")
  if (is.na(val) || !nzchar(val)) {
    return("unknown")
  }
  val
}







#' Extract Year from a GEDCOM Date String
#'
#' Extracts a four-digit year from a GEDCOM date string, stripping calendar
#' escapes (e.g., `\@#DGREGORIAN\@`) and common qualifiers (`ABT`, `BEF`,
#' `AFT`, `BET`/`AND`) before searching for the year. Returns `NA_integer_`
#' when no four-digit year is found.
#'
#' @param x Character vector of GEDCOM date strings.
#' @return Integer vector of years.
#' @examples
#' extractGedcomYear(c("ABT 1 JAN 1900", "BEF 31 DEC 2000", "1850", NA))
#' @export
#' @importFrom stringr str_extract
extractGedcomYear <- function(x) {
  x <- gsub("@#D[A-Z ]+@\\s*", "", x)
  x <- gsub("\\b(?:ABT|BEF|AFT|BET|AND)\\.?\\s*", "", x,
    ignore.case = TRUE, perl = TRUE
  )
  as.integer(stringr::str_extract(x, "\\b\\d{4}\\b"))
}
