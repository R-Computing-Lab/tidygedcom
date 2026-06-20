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

  # Build mapping tables once; passed into each block parser rather than rebuilt per block.
  mappings <- list(
    event_fields          = make_event_fields(),
    name_piece_mappings   = make_name_piece_mappings(),
    attribute_mappings    = make_attribute_mappings(),
    relationship_mappings = make_relationship_mappings()
  )

  # Parse each individual block into a record (a named list)
  records <- lapply(blocks, parseIndividualBlock,
    pattern_rows = pattern_rows,
    all_var_names = all_var_names,
    mappings = mappings,
    verbose = verbose
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
