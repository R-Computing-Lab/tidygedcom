#' Convert GEDCOM Latitude String to Numeric
#'
#' Converts GEDCOM-style latitude strings like `"N51.5074"` or `"S33.8688"` to
#' signed decimal degrees. Returns `NA` for `NA` or unrecognised-prefix input.
#'
#' @param x Character vector of GEDCOM latitude values.
#' @return Numeric vector of decimal degrees (positive = N, negative = S).
#' @examples
#' gedcomLat2Numeric(c("N51.5074", "S33.8688", NA))
#' @export
gedcomLat2Numeric <- function(x) {
  out <- rep(NA_real_, length(x))
  ok <- !is.na(x) & (startsWith(x, "N") | startsWith(x, "S"))
  out[ok] <- as.numeric(substring(x[ok], 2)) *
    ifelse(startsWith(x[ok], "N"), 1, -1)
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
gedcomLon2Numeric <- function(x) {
  out <- rep(NA_real_, length(x))
  ok <- !is.na(x) & (startsWith(x, "E") | startsWith(x, "W"))
  out[ok] <- as.numeric(substring(x[ok], 2)) *
    ifelse(startsWith(x[ok], "E"), 1, -1)
  out
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
  if (is.null(lat_cols)) {
    lat_cols <- grep("_lat$", colnames(df), value = TRUE)
  }
  if (is.null(long_cols)) {
    long_cols <- grep("_long$", colnames(df), value = TRUE)
  }
  df[lat_cols] <- lapply(df[lat_cols], gedcomLat2Numeric)
  df[long_cols] <- lapply(df[long_cols], gedcomLon2Numeric)
  df
}
