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
