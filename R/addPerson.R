#' @title addPersonToPed
#' @description A function to add a new person to an existing pedigree \code{data.frame}.
#' @param ped A \code{data.frame} representing the existing pedigree.
#' @param name Optional. A character string representing the name of the new
#' person. If not provided, the name will be set to \code{NA}.
#' @param sex A value representing the sex of the new person.
#' @param momID Optional. The ID of the mother of the new person. If not
#' provided, it will be set to \code{NA}.
#' @param dadID Optional. The ID of the father of the new person. If not
#' provided, it will be set to \code{NA}.
#' @param twinID Optional. The ID of the twin of the new person. If not
#' provided, it will be set to \code{NA}.
#' @param zygosity Optional. A character string indicating the zygosity of the
#' new person. If not provided, it will be set to \code{NA}.
#' @param personID Optional. The ID of the new person. If not provided, it will
#' be generated as the maximum existing personID + 1.
#' @param notes Optional. A character string for notes about the new person. If
#' not provided, it will be set to \code{NA}.
#' @param url Optional. A URL column for the new person. If not provided, it
#' will be set to \code{NA}.
#' @param overwrite Logical. If \code{TRUE}, the function will overwrite an
#' existing person with the same \code{personID}. If \code{FALSE}, it will stop
#' if a person with the same
#' \code{personID} already exists.
#'
#' @return A \code{data.frame} with the new person added to the existing pedigree.
#'
#' @export
#'
addPersonToPed <- function(ped, name = NULL,
                           sex = NULL, momID = NA,
                           dadID = NA, twinID = NULL,
                           personID = NULL, zygosity = NULL,
                           notes = NULL, url = NULL,
                           overwrite = FALSE) {
  stopifnot(is.data.frame(ped))
  if (overwrite == TRUE) {
    # Check if the personID already exists in the pedigree
    # Copy structure from an existing row

    new_row <- ped[ped$personID == personID, ]
    # drop the row with the personID
    if (nrow(new_row) == 0) {
      stop("The personID does not exist in the pedigree. Set overwrite=FALSE to add a new person with a new ID.")
    }
    # Remove the row with the personID
    # ped <-  ped[ped$personID!=personID, ]
  } else {
    # Check if the personID already exists in the pedigree
    if (!is.null(personID) && personID %in% ped$personID) {
      stop("The personID already exists in the pedigree. Set overwrite=TRUE to overwrite the existing person.")
    }

    # Copy structure from an existing row
    new_row <- ped[1, , drop = FALSE]

    # Blank out all values
    new_row[1, ] <- NA
  }
  # Assign new values
  if (!is.null(personID)) {
    new_row$personID <- personID
  } else {
    # Generate a new personID based on the maximum existing personID
    new_row$personID <- max(ped$personID, na.rm = TRUE) + 1
  }
  if (!is.null(name) && "name" %in% colnames(ped)) {
    new_row$name <- name
  } else if ("name" %in% colnames(ped)) {
    new_row$name <- NA_character_
  }
  if (!is.null(twinID) && "twinID" %in% colnames(ped)) {
    new_row$twinID <- twinID
  } else if ("twinID" %in% colnames(ped)) {
    new_row$twinID <- NA_integer_
  }
  if (!is.null(momID) && "momID" %in% colnames(ped)) {
    new_row$momID <- momID
  } else if ("momID" %in% colnames(ped)) {
    new_row$momID <- NA_integer_
  }
  if (!is.null(dadID) && "dadID" %in% colnames(ped)) {
    new_row$dadID <- dadID
  } else if ("dadID" %in% colnames(ped)) {
    new_row$dadID <- NA_integer_
  }
  if (!is.null(sex) && "sex" %in% colnames(ped)) {
    new_row$sex <- sex
  } else if ("sex" %in% colnames(ped)) {
    new_row$sex <- NA_character_
  }
  if (!is.null(zygosity) && "zygosity" %in% colnames(ped)) {
    new_row$zygosity <- zygosity
  } else if ("zygosity" %in% colnames(ped)) {
    new_row$zygosity <- NA_character_
  }
  if (!is.null(notes) && "notes" %in% colnames(ped)) {
    new_row$notes <- notes
  } else if ("notes" %in% colnames(ped)) {
    new_row$notes <- NA_character_
  }
  if (!is.null(url) && "url" %in% colnames(ped)) {
    new_row$url <- url
  } else if ("url" %in% colnames(ped)) {
    new_row$url <- NA_character_
  }
  # Append to data frame
  if (overwrite == TRUE) {
    ped[ped$personID == personID, ] <- new_row

    return(ped)
  } else {
    return(rbind(ped, new_row))
  }
}
