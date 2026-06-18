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


#' collapse Names
#'
#' This function combines the `name_given` and `name_given_pieces` columns in a data frame. If both columns have non-missing values that differ, a warning is issued and the original `name_given` is retained. If one column is missing, the other is used. The same logic applies to the `name_surn` and `name_surn_pieces` columns.
#'
#' @inheritParams readGedcom
#' @param df_temp A data frame containing the columns to be combined.
#' @return A data frame with the combined columns.
#' @keywords internal


collapseNames <- function(verbose, df_temp) {
  if (verbose == TRUE) {
    message("Combining Duplicate Name Columns...")
  }

  if (!all(is.na(df_temp$name_given_pieces)) || !all(is.na(df_temp$name_given))) {
    result <- combineColumns(df_temp$name_given, df_temp$name_given_pieces)
    df_temp$name_given <- result$combined
    if (!result$retain_col2) df_temp$name_given_pieces <- NULL
  }

  if (!all(is.na(df_temp$name_surn_pieces)) || !all(is.na(df_temp$name_surn))) {
    result <- combineColumns(df_temp$name_surn, df_temp$name_surn_pieces)
    df_temp$name_surn <- result$combined
    if (!result$retain_col2) df_temp$name_surn_pieces <- NULL
  }
  df_temp
}

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

#' Convert GEDCOM Latitude String to Numeric
#'
#' Converts GEDCOM-style latitude strings like `"N51.5074"` or `"S33.8688"` to
#' signed decimal degrees. Returns `NA` for `NA` or unrecognised-prefix input.
#'
#' @param x Character vector of GEDCOM latitude values.
#' @return Numeric vector of decimal degrees (positive = N, negative = S).
#' @examples
#' gedcomLatToNumeric(c("N51.5074", "S33.8688", NA))
#' @export
gedcomLatToNumeric <- function(x) {
  out <- rep(NA_real_, length(x))
  ok <- !is.na(x) & (startsWith(x, "N") | startsWith(x, "S"))
  out[ok] <- as.numeric(substring(x[ok], 2)) * ifelse(startsWith(x[ok], "N"), 1, -1)
  out
}

#' Convert GEDCOM Longitude String to Numeric
#'
#' Converts GEDCOM-style longitude strings like `"E151.2093"` or `"W0.1278"` to
#' signed decimal degrees. Returns `NA` for `NA` or unrecognized-prefix input.
#'
#' @param x Character vector of GEDCOM longitude values.
#' @return Numeric vector of decimal degrees (positive = E, negative = W).
#' @examples
#' gedcomLonToNumeric(c("E151.2093", "W0.1278", NA))
#' @export
gedcomLonToNumeric <- function(x) {
  out <- rep(NA_real_, length(x))
  ok <- !is.na(x) & (startsWith(x, "E") | startsWith(x, "W"))
  out[ok] <- as.numeric(substring(x[ok], 2)) * ifelse(startsWith(x[ok], "E"), 1, -1)
  out
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


#' Convert GEDCOM Coordinate Columns to Numeric
#'
#' Converts all latitude and longitude columns in a parsed GEDCOM data frame
#' from GEDCOM compass-prefix notation (e.g., `"N51.5074"`, `"W0.1278"`) to
#' signed decimal degrees. By default, all columns whose names end in `_lat`
#' or `_long` are converted.
#'
#' @param df A data frame, typically returned by \code{readGedcom()}.
#' @param lat_cols Character vector of latitude column names to convert.
#'   Defaults to all columns ending in `"_lat"`.
#' @param long_cols Character vector of longitude column names to convert.
#'   Defaults to all columns ending in `"_long"`.
#' @return The data frame with the specified columns replaced by numeric values.
#' @examples
#' df <- data.frame(
#'   birth_lat = "N51.5074", birth_long = "W0.1278",
#'   stringsAsFactors = FALSE
#' )
#' convertGedcomCoords(df)
#' @export
convertGedcomCoords <- function(df, lat_cols = NULL, long_cols = NULL) {
  if (is.null(lat_cols)) lat_cols <- grep("_lat$", colnames(df), value = TRUE)
  if (is.null(long_cols)) long_cols <- grep("_long$", colnames(df), value = TRUE)
  df[lat_cols] <- lapply(df[lat_cols], gedcomLatToNumeric)
  df[long_cols] <- lapply(df[long_cols], gedcomLonToNumeric)
  df
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


#' Summarise a Parsed GEDCOM Data Frame
#'
#' Returns key counts and coverage statistics for a data frame produced by
#' \code{readGedcom()}.
#'
#' @param df A data frame returned by \code{readGedcom()}.
#' @return An object of class \code{"tidygedcom_summary"} (a named list).
#'   Print the result for a human-readable overview.
#' @examples
#' \dontrun{
#' df <- readGedcom("my_file.ged")
#' summarizeGedcom(df)
#' }
#' @export
summarizeGedcom <- function(df) {
  stopifnot(is.data.frame(df))

  n_total <- nrow(df)
  n_male <- if ("sex" %in% colnames(df)) sum(df$sex == "M", na.rm = TRUE) else NA_integer_
  n_female <- if ("sex" %in% colnames(df)) sum(df$sex == "F", na.rm = TRUE) else NA_integer_
  n_unknown_sex <- if (!is.na(n_male)) n_total - n_male - n_female else NA_integer_

  count_non_na <- function(col) if (col %in% colnames(df)) sum(!is.na(df[[col]])) else NA_integer_

  out <- list(
    n_individuals = n_total,
    n_male = n_male,
    n_female = n_female,
    n_unknown_sex = n_unknown_sex,
    n_with_birth_date = count_non_na("birth_date"),
    n_with_death_date = count_non_na("death_date"),
    n_with_chr_date = count_non_na("chr_date"),
    n_with_burial_date = count_non_na("burial_date"),
    n_with_mom = count_non_na("momID"),
    n_with_dad = count_non_na("dadID"),
    n_with_birth_place = count_non_na("birth_place"),
    n_with_death_place = count_non_na("death_place"),
    gedcom_version = attr(df, "gedcom_version")
  )

  class(out) <- "tidygedcom_summary"
  out
}

#' @export
print.tidygedcom_summary <- function(x, ...) {
  ver <- if (!is.null(x$gedcom_version)) x$gedcom_version else "unknown"
  cat("GEDCOM Summary  (version:", ver, ")\n")
  cat("  Individuals:", x$n_individuals, "\n")
  if (!is.na(x$n_male)) {
    cat(
      "  Sex: M =", x$n_male, "| F =", x$n_female,
      "| Unknown =", x$n_unknown_sex, "\n"
    )
  }
  pct <- function(n) if (!is.na(n)) paste0(" (", round(100 * n / x$n_individuals), "%)") else ""
  if (!is.na(x$n_with_birth_date)) {
    cat("  With birth date:", x$n_with_birth_date, pct(x$n_with_birth_date), "\n")
  }
  if (!is.na(x$n_with_chr_date) && x$n_with_chr_date > 0) {
    cat("  With christening date:", x$n_with_chr_date, pct(x$n_with_chr_date), "\n")
  }
  if (!is.na(x$n_with_death_date)) {
    cat("  With death date:", x$n_with_death_date, pct(x$n_with_death_date), "\n")
  }
  if (!is.na(x$n_with_burial_date) && x$n_with_burial_date > 0) {
    cat("  With burial date:", x$n_with_burial_date, pct(x$n_with_burial_date), "\n")
  }
  if (!is.na(x$n_with_birth_place)) {
    cat("  With birth place:", x$n_with_birth_place, pct(x$n_with_birth_place), "\n")
  }
  if (!is.na(x$n_with_death_place)) {
    cat("  With death place:", x$n_with_death_place, pct(x$n_with_death_place), "\n")
  }
  if (!is.na(x$n_with_mom)) {
    cat("  With known mother:", x$n_with_mom, pct(x$n_with_mom), "\n")
  }
  if (!is.na(x$n_with_dad)) {
    cat("  With known father:", x$n_with_dad, pct(x$n_with_dad), "\n")
  }
  invisible(x)
}
