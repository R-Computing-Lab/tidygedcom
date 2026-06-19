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
