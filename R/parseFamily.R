# --- Family Records ---

#' Read Family Records from a GEDCOM File
#'
#' Parses `FAM` records from a GEDCOM file and returns a tidy data frame with
#' one row per family unit. Captures husband, wife, children, marriage event,
#' and divorce event details.
#'
#' @param file_path Character string. Path to the GEDCOM file.
#' @param verbose Logical. If `TRUE`, print progress messages.
#' @param parse_dates Logical. If `TRUE`, attempt to parse `marr_date` and
#'   `div_date` into `Date` objects, after stripping common GEDCOM qualifiers.
#' @param remove_empty_cols Logical. If `TRUE`, drop columns that are entirely `NA`.
#' @param ... Additional arguments. Currently unused.
#' @return A data frame with one row per `FAM` record and the following columns:
#' \describe{
#'   \item{famID}{Family identifier from the `@ FAM` line.}
#'   \item{husbID}{Person ID of the husband (`HUSB` tag).}
#'   \item{wifeID}{Person ID of the wife (`WIFE` tag).}
#'   \item{children}{Comma-separated person IDs of children (`CHIL` tags).}
#'   \item{marr_date}{Marriage date (`MARR/DATE`).}
#'   \item{marr_place}{Marriage place (`MARR/PLAC`).}
#'   \item{marr_lat}{Marriage latitude (`MARR/.../LATI`).}
#'   \item{marr_long}{Marriage longitude (`MARR/.../LONG`).}
#'   \item{div_date}{Divorce date (`DIV/DATE`).}
#'   \item{div_place}{Divorce place (`DIV/PLAC`).}
#' }
#' Returns `NULL` with a warning if no family records are found.
#' @export
readGedcomFamilies <- function(file_path,
                               verbose = FALSE,
                               parse_dates = FALSE,
                               remove_empty_cols = TRUE,
                               ...) {
  if (!file.exists(file_path)) stop("File does not exist: ", file_path)
  if (verbose) message("Reading file: ", file_path)
  lines <- readLines(file_path)
  if (verbose) message("File is ", length(lines), " lines long")

  blocks <- splitFamilies(lines, verbose)
  if (length(blocks) == 0) {
    warning("No family records found in file")
    return(NULL)
  }

  records <- lapply(blocks, parseFamilyBlock, verbose = verbose)
  records <- Filter(Negate(is.null), records)

  if (length(records) == 0) {
    warning("No valid family records parsed")
    return(NULL)
  }

  df <- do.call(rbind, lapply(records, as.data.frame, stringsAsFactors = FALSE))

  if (parse_dates) {
    date_cols <- c("marr_date", "div_date")
    present <- date_cols[date_cols %in% colnames(df)]
    if (length(present) > 0) {
      calendar_escape_regex <- "@#D[A-Z ]+@\\s*"
      qualifier_regex <- "\\b(?:[aA][bBfF][tT]|[bB][eE][tTfF])\\.?\\b\\s*"
      df[present] <- lapply(df[present], function(x) {
        if (is.character(x)) {
          x <- stringr::str_replace_all(x, calendar_escape_regex, "")
          x <- stringr::str_replace_all(x, qualifier_regex, "")
          as.Date(stringr::str_trim(x), format = "%d %b %Y")
        } else {
          x
        }
      })
    }
  }

  if (remove_empty_cols) {
    df <- df[, colSums(is.na(df)) < nrow(df), drop = FALSE]
  }

  df
}

#' Split GEDCOM Lines into Family Blocks
#'
#' @param lines Character vector of lines from a GEDCOM file.
#' @param verbose Logical. If `TRUE`, print progress messages.
#' @return A list of character vectors, each representing one FAM record.
#' @keywords internal
splitFamilies <- function(lines, verbose = FALSE) {
  fam_idx <- grep("@ FAM\\b", lines)
  if (length(fam_idx) == 0) {
    return(list())
  }

  record_idx <- grep("@ (INDI|FAM|SOUR|REPO|OBJE|SUB[MN]|NOTE|_MTCAT)\\b| TRLR\\b", lines)

  blocks <- vector("list", length(fam_idx))
  for (i in seq_along(fam_idx)) {
    start <- fam_idx[i]
    next_record <- record_idx[record_idx > start]
    end <- if (length(next_record) > 0) next_record[1L] - 1L else length(lines)
    blocks[[i]] <- lines[start:end]
  }
  if (verbose) message("Found ", length(blocks), " family blocks")
  blocks
}

#' Parse a GEDCOM Family Block
#'
#' @param block Character vector of GEDCOM lines for one FAM record.
#' @param verbose Logical. Currently unused.
#' @return A named list with family fields, or `NULL` if no family ID is found.
#' @keywords internal
#' @importFrom stringr str_extract str_trim
parseFamilyBlock <- function(block, verbose = FALSE) {
  famID <- stringr::str_extract(block[1L], "(?<=@.)\\d*(?=@)")
  if (is.na(famID) || !nzchar(famID)) {
    return(NULL)
  }

  record <- list(
    famID = famID,
    husbID = NA_character_,
    wifeID = NA_character_,
    children = NA_character_,
    marr_date = NA_character_,
    marr_place = NA_character_,
    marr_lat = NA_character_,
    marr_long = NA_character_,
    div_date = NA_character_,
    div_place = NA_character_
  )

  n <- length(block)
  i <- 1L
  while (i <= n) {
    line <- block[i]

    if (grepl("\\bHUSB\\b", line)) {
      record$husbID <- stringr::str_extract(line, "(?<=@.)\\d*(?=@)")
    } else if (grepl("\\bWIFE\\b", line)) {
      record$wifeID <- stringr::str_extract(line, "(?<=@.)\\d*(?=@)")
    } else if (grepl("\\bCHIL\\b", line)) {
      child_id <- stringr::str_extract(line, "(?<=@.)\\d*(?=@)")
      record$children <- if (is.na(record$children)) {
        child_id
      } else {
        paste0(record$children, ", ", child_id)
      }
    } else if (grepl("\\bMARR\\b", line)) {
      sub_block <- extractEventSubBlock(block, i)
      if (length(sub_block) > 0L) {
        event_level <- extractGedcomLevel(block[i])
        direct_children <- sub_block[
          vapply(sub_block, extractGedcomLevel, integer(1L)) == event_level + 1L
        ]
        record$marr_date <- extractInfoFromLines(direct_children, "DATE")
        record$marr_place <- extractInfoFromLines(direct_children, "PLAC")
        record$marr_lat <- extractCoordFromSubBlock(sub_block, "LATI")
        record$marr_long <- extractCoordFromSubBlock(sub_block, "LONG")
      }
    } else if (grepl("\\bDIV\\b", line)) {
      sub_block <- extractEventSubBlock(block, i)
      if (length(sub_block) > 0L) {
        event_level <- extractGedcomLevel(block[i])
        direct_children <- sub_block[
          vapply(sub_block, extractGedcomLevel, integer(1L)) == event_level + 1L
        ]
        record$div_date <- extractInfoFromLines(direct_children, "DATE")
        record$div_place <- extractInfoFromLines(direct_children, "PLAC")
      }
    }

    i <- i + 1L
  }

  record
}

#' Process Parents Information from GEDCOM Data
#'
#' @description This function adds mother and father IDs to individuals in the data frame
#'
#' @param df_temp A data frame produced by \code{readGedcom()}.
#' @param datasource Character string indicating the data source ("gedcom" or "wiki").
#' @param person_id_col Character string indicating the column name for individual IDs (default "personID").
#' @return The updated data frame with parent IDs added.
#' @keywords internal

processParents <- function(df_temp, datasource, person_id_col = "personID") {
  if (datasource %in% c("gedcom", "ged")) {
    required_cols <- c("FAMC", "sex", "FAMS")
  } else if (datasource == "wiki") {
    required_cols <- c(person_id_col)
  } else {
    stop("Invalid datasource")
  }
  if (!all(required_cols %in% colnames(df_temp))) {
    missing_cols <- setdiff(required_cols, colnames(df_temp))
    warning("Missing necessary columns: ", paste(missing_cols, collapse = ", "))
    return(df_temp)
  }
  family_to_parents <- mapFAMS2parents(df_temp)
  if (is.null(family_to_parents) || length(family_to_parents) == 0) {
    return(df_temp)
  }
  df_temp <- mapFAMC2parents(df_temp, family_to_parents)
  df_temp
}

#' Create a Mapping from Family IDs to Parent IDs
#'
#' This function scans the data frame and creates a mapping of family IDs
#' to the corresponding parent IDs.
#'
#' @param df_temp A data frame produced by \code{readGedcom()}.
#' @param mom_sex Character string indicating the value of sex that corresponds to mothers (default "F").
#' @param dad_sex Character string indicating the value of sex that corresponds to fathers (default "M").
#' @return A list mapping family IDs to parent information.
mapFAMS2parents <- function(df_temp,
                            mom_sex = "F",
                            dad_sex = "M") {
  if (!all(c("FAMS", "sex") %in% colnames(df_temp))) {
    warning("The data frame does not contain the necessary columns (FAMS, sex)")
    return(NULL)
  }
  family_to_parents <- list()
  for (i in seq_len(nrow(df_temp))) {
    if (!is.na(df_temp$FAMS[i])) {
      fams_ids <- unlist(strsplit(df_temp$FAMS[i], ", "))
      for (fams_id in fams_ids) {
        if (!is.null(family_to_parents[[fams_id]])) {
          if (df_temp$sex[i] == dad_sex) {
            family_to_parents[[fams_id]]$father <- df_temp$personID[i]
          } else if (df_temp$sex[i] == mom_sex) {
            family_to_parents[[fams_id]]$mother <- df_temp$personID[i]
          }
        } else {
          family_to_parents[[fams_id]] <- list()
          if (df_temp$sex[i] == dad_sex) {
            family_to_parents[[fams_id]]$father <- df_temp$personID[i]
          } else if (df_temp$sex[i] == mom_sex) {
            family_to_parents[[fams_id]]$mother <- df_temp$personID[i]
          }
        }
      }
    }
  }
  family_to_parents
}

#' Assign momID and dadID based on family mapping
#'
#' This function assigns mother and father IDs to individuals in the data frame
#' based on the mapping of family IDs to parent IDs. It updates the data frame in place.
#'
#' @param df_temp A data frame containing individual information.
#' @param family_to_parents A list mapping family IDs to parent IDs.
#' @return A data frame with added momID and dad_ID columns.
#' @keywords internal
#'
mapFAMC2parents <- function(df_temp, family_to_parents) {
  df_temp$momID <- NA_character_
  df_temp$dadID <- NA_character_
  for (i in seq_len(nrow(df_temp))) {
    if (!is.na(df_temp$FAMC[i])) {
      famc_ids <- unlist(strsplit(df_temp$FAMC[i], ", "))
      for (famc_id in famc_ids) {
        if (!is.null(family_to_parents[[famc_id]])) {
          if (!is.null(family_to_parents[[famc_id]]$father)) {
            df_temp$dadID[i] <- family_to_parents[[famc_id]]$father
          }
          if (!is.null(family_to_parents[[famc_id]]$mother)) {
            df_temp$momID[i] <- family_to_parents[[famc_id]]$mother
          }
        }
      }
    }
  }
  df_temp
}

