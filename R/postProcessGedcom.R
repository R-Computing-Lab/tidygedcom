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
  if (isTRUE(add_parents)) {
    if (isTRUE(verbose)) message("Processing parents")
    df_temp <- processParents(df_temp, datasource = "gedcom")
  }
  if (combine_cols == TRUE) {
    df_temp <- collapseNames(verbose = verbose, df_temp = df_temp)
  }
  if (remove_empty_cols == TRUE || skinny == TRUE) {
    if (isTRUE(verbose)) message("Removing empty columns")
    df_temp <- df_temp[, colSums(is.na(df_temp)) < nrow(df_temp)]
  }
  if (parse_dates == TRUE) {
    date_cols <- c("birth_date", "death_date")
    calendar_escape_regex <- "@#D[A-Z ]+@\\s*"
    date_qualifier_regex <- "\\b(?:[aA][bBfF][tT]|[bB][eE][tTfF])\\.?\\b\\s*"

    if (isTRUE(verbose)) {
      message("Parsing date columns: ", paste(date_cols[date_cols %in% colnames(df_temp)], collapse = ", "))
    }

    if (isTRUE(verbose) && any(date_cols %in% colnames(df_temp))) {
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
    if (isTRUE(verbose)) message("Cleaning column names")
    name_cols <- grep("^name", colnames(df_temp), value = TRUE)
    if (isTRUE(verbose) && any(name_cols %in% colnames(df_temp))) {
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
#' @inheritParams processParents
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
#' @inheritParams processParents
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
