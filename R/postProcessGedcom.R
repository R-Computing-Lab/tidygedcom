#' Post-process GEDCOM Data Frame
#'
#' @description This function optionally adds parent information, combines duplicate columns,
#' and removes empty columns from the GEDCOM data frame. It is called by \code{readGedcom()} if \code{post_process = TRUE}.
#' @inheritParams readGedcom
#' @param df_temp A data frame produced by \code{readGedcom()}.
#' @param verbose Logical indicating whether to print progress messages.
#' @return The post-processed data frame.
#' @keywords internal
#' @importFrom stringr str_replace_all str_trim str_squish
postProcessGedcom <- function(df_temp,
                              remove_empty_cols = TRUE,
                              combine_cols = TRUE,
                              add_parents = TRUE,
                              parse_dates = FALSE,
                              clean_names = TRUE,
                              skinny = TRUE,
                              verbose = FALSE) {
  if (add_parents == TRUE) {
    if (verbose == TRUE) message("Processing parents")
    df_temp <- processParents(df_temp, datasource = "gedcom")
  }
  if (combine_cols == TRUE) {
    df_temp <- collapseNames(verbose = verbose, df_temp = df_temp)
  }
  if (remove_empty_cols == TRUE || skinny == TRUE) {
    if (verbose == TRUE) message("Removing empty columns")
    df_temp <- df_temp[, colSums(is.na(df_temp)) < nrow(df_temp)]
  }
  if (parse_dates == TRUE) {
    date_cols <- c("birth_date", "death_date")
    calendar_escape_regex <- "@#D[A-Z ]+@\\s*"
    date_qualifier_regex <- "\\b(?:[aA][bBfF][tT]|[bB][eE][tTfF])\\.?\\b\\s*"

    if (verbose == TRUE) {
      message("Parsing date columns: ", paste(date_cols[date_cols %in% colnames(df_temp)], collapse = ", "))
    }

    if (verbose == TRUE && any(date_cols %in% colnames(df_temp))) {
      has_qualifiers <- any(sapply(
        df_temp[date_cols[date_cols %in% colnames(df_temp)]],
        function(col) any(grepl(date_qualifier_regex, col, perl = TRUE))
      ))
      if (has_qualifiers == TRUE) {
        message("Found date qualifiers in date columns. They will be removed before parsing.")
      }
    }

    # only parse date columns that are present in the data frame
    present_date_cols <- date_cols[date_cols %in% colnames(df_temp)]
    if (length(present_date_cols) > 0) {
      df_temp[present_date_cols] <- lapply(df_temp[present_date_cols], function(x) {
        if (is.character(x)) {
          x <- stringr::str_replace_all(x, calendar_escape_regex, "")
          x <- stringr::str_replace_all(x, date_qualifier_regex, "")
          as.Date(stringr::str_trim(x), format = "%d %b %Y")
        } else {
          x
        }
      })
    }
  }
  if (clean_names == TRUE) {
    if (verbose == TRUE) message("Cleaning column names")
    name_cols <- grep("^name", colnames(df_temp), value = TRUE)
    if (verbose == TRUE && any(name_cols %in% colnames(df_temp))) {
      message("Cleaning name columns: ", paste(name_cols, collapse = ", "))
    }
    df_temp[name_cols] <- lapply(df_temp[name_cols], function(x) {
      if (is.character(x)) { # remove / at end of names if present, and squish whitespace
        stringr::str_squish(stringr::str_replace(x, "/+$", ""))
      } else {
        x
      }
    })
  }
  if (skinny == TRUE) {
    if (verbose == TRUE) message("Slimming down the data frame")
    # Remove raw family relationship columns
    df_temp$FAMC <- NULL
    df_temp$FAMS <- NULL
  }
  df_temp
}
