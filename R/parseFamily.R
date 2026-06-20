#' Read Family Records from a GEDCOM File
#'
#' Parses `FAM` records from a GEDCOM file and returns a tidy data frame with
#' one row per family unit. Captures husband, wife, children, marriage event,
#' and divorce event details.
#' @inheritParams readGedcom
#' @param parse_dates Logical. If `TRUE`, attempt to parse `marr_date` and
#'   `div_date` into `Date` objects, after stripping common GEDCOM qualifiers.
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
#' @inheritParams readGedcom
#' @param lines Character vector of lines from a GEDCOM file.
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
#' @inheritParams readGedcom
#' @param block Character vector of GEDCOM lines for one FAM record.
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
