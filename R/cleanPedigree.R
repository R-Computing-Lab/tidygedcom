#' Slice a Pedigree Down to the Rows Referencing an ID
#'
#' Given a pedigree data frame, returns every row in which any of the supplied
#' IDs appears as the individual themselves, a parent, or a spouse. This is a
#' diagnostic aid for inspecting a person's full household before and after
#' manually repairing links in GEDCOM-derived pedigrees. The result is a subset
#' of `ped` with the same columns, so it parallels [BGmisc::sliceFamilies()],
#' which slices a pedigree down to families meeting a criterion.
#'
#' Incoming column names are normalised with BGmisc's internal column
#' standardiser, so the common variants (`ID`/`personID`, `dadID`/`pid_fath`,
#' `momID`/`pid_moth`, `spID`/`pid_spouse1`, ...) are all recognised without the
#' caller naming them. Because BGmisc's canonical schema is single-spouse but
#' GEDCOM-derived pedigrees often record remarriages in extra columns, any
#' additional spouse-like columns (matching `spID2`, `pid_spouse2`, ...) are
#' detected and searched too. The returned rows keep the caller's original
#' column names.
#'
#' @param ped A pedigree data frame.
#' @param ID A vector of one or more IDs to slice on.
#' @param sort Logical. If `TRUE` (default), sort the result by father ID then
#'   individual ID.
#' @return A data frame: the subset of `ped` rows in which any of `ID` appears in
#'   a linking column, with the original columns and names preserved.
#' @examples
#' \dontrun{
#' # Inspect a couple's full household before repairing a link
#' sliceByID(ped, ID = c(348700, 348701))
#' }
#' @export
sliceByID <- function(ped, ID, sort = TRUE) {
  # Standardise a throwaway copy only to locate the linking columns; the copy's
  # canonical names line up 1:1 with the original columns by position, so the
  # match mask computed here indexes back into the untouched `ped`.
  std <- BGmisc:::standardizeColnames(ped)

  # BGmisc canonical linking slots, plus any extra spouse-like columns the
  # single-spouse standardiser leaves untouched (e.g. spID2, pid_spouse3).
  canonical <- c("ID", "momID", "dadID", "matID", "patID", "spID")
  extra_spouse <- grep("^sp(id)?[0-9]+$|spouse", names(std),
    ignore.case = TRUE, value = TRUE
  )
  link_cols <- unique(c(intersect(canonical, names(std)), extra_spouse))

  if (length(link_cols) == 0) {
    stop("Could not find any linking columns (ID, parents, or spouses) in `ped`.")
  }

  mask <- Reduce(`|`, lapply(link_cols, function(col) std[[col]] %in% ID))
  out <- ped[mask, , drop = FALSE]

  if (sort) {
    std_out <- std[mask, , drop = FALSE]
    sort_cols <- intersect(c("dadID", "ID"), names(std_out))
    if (length(sort_cols) > 0) {
      out <- out[order(do.call(paste, std_out[sort_cols])), , drop = FALSE]
    }
  }

  out
}


#' Find Where One or More IDs Occur Across a List of Data Frames
#'
#' Searches a named list of data frames for the supplied IDs, looking in every
#' column whose name matches `id_regex` (parent, spouse, and person-ID columns
#' by default). Returns one row per hit, recording which dataset, which column,
#' and which row the ID was found in, alongside any requested context columns.
#' This is the detective step of link repair: locating every place an ID lives
#' before deciding how to fix it.
#'
#' Unlike [sliceByID()], this does *not* standardise column names, because its
#' whole purpose is to catch IDs wherever they hide, including in non-canonical
#' columns.
#'
#' @param data_list A named list of data frames to search.
#' @param ID A vector of one or more IDs to search for.
#' @param id_regex Regular expression matched against column names to decide
#'   which columns are ID columns. Ignored when `include_all_id_cols = TRUE`.
#' @param context_cols Character vector of additional (non-ID) columns to carry
#'   through for context. Columns absent from a given data frame are ignored.
#' @param ignore_case Logical. Match `id_regex` case-insensitively. Default
#'   `TRUE`.
#' @param include_all_id_cols Logical. If `TRUE`, search every column rather
#'   than only those matching `id_regex`. Default `FALSE`.
#' @return A data frame with one row per match, containing `matched_id`,
#'   `dataset`, `matched_column`, `matched_value`, the source `row_index`, and
#'   any available `context_cols`. Returns an empty data frame if nothing
#'   matches.
#' @examples
#' \dontrun{
#' findIDs(list(clean = clean_df, raw = raw_df), ID = 389785)
#' }
#' @importFrom dplyr %>%
#' @importFrom rlang .data
#' @export
findIDs <- function(data_list, ID,
                    id_regex = "(^id$|id$|^pid|pid$|pid_|dadid|momid|patid|matid|spid|spouse|sire|dame)",
                    context_cols = c("sex", "byr", "dyr", "name"),
                    ignore_case = TRUE,
                    include_all_id_cols = FALSE) {
  stopifnot(is.list(data_list), !is.null(names(data_list)))
  ID_chr <- as.character(ID)

  find_id_cols <- function(df) {
    nm <- names(df)
    if (include_all_id_cols) {
      return(nm)
    }
    nm[stringr::str_detect(nm, stringr::regex(id_regex, ignore_case = ignore_case))]
  }

  search_one <- function(df, dataset_name) {
    if (!inherits(df, "data.frame")) {
      return(NULL)
    }
    id_cols <- find_id_cols(df)
    if (length(id_cols) == 0) {
      return(NULL)
    }
    keep_context <- setdiff(context_cols, id_cols)
    df %>%
      dplyr::mutate(row_index = dplyr::row_number()) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.character)) %>%
      dplyr::select(
        "row_index",
        dplyr::all_of(id_cols),
        dplyr::any_of(keep_context)
      ) %>%
      tidyr::pivot_longer(
        cols = dplyr::all_of(id_cols),
        names_to = "matched_column",
        values_to = "matched_value"
      ) %>%
      dplyr::filter(.data$matched_value %in% ID_chr) %>%
      dplyr::mutate(
        matched_id = .data$matched_value,
        dataset = dataset_name,
        .before = 1
      )
  }

  purrr::imap(data_list, search_one) %>%
    dplyr::bind_rows() %>%
    dplyr::arrange(
      .data$matched_id, .data$dataset,
      .data$matched_column, .data$row_index
    )
}


#' Summarize Where One or More IDs Occur Across a List of Data Frames
#'
#' A count-level companion to [findIDs()]: instead of one row per hit, returns
#' one row per (id, dataset, column) with the number of matches. Useful for a
#' quick census of how many places an ID appears before drilling in with
#' [findIDs()].
#'
#' @inheritParams findIDs
#' @param ... Additional arguments passed to [findIDs()].
#' @return A data frame with columns `matched_id`, `dataset`, `matched_column`,
#'   and `n_matches`.
#' @examples
#' \dontrun{
#' summarizeIDs(list(clean = clean_df, raw = raw_df), ID = 389785)
#' }
#' @importFrom dplyr %>%
#' @importFrom rlang .data
#' @export
summarizeIDs <- function(data_list, ID, ...) {
  findIDs(data_list, ID, ...) %>%
    dplyr::count(
      .data$matched_id, .data$dataset, .data$matched_column,
      name = "n_matches"
    ) %>%
    dplyr::arrange(.data$matched_id, .data$dataset, .data$matched_column)
}

#' @rdname summarizeIDs
#' @export
summariseIDs <- summarizeIDs


#' Apply a List of Hand-Verified Fixes to a Pedigree
#'
#' Applies a set of manual corrections to a pedigree data frame, recording the
#' provenance of each edit in `manual_fix` and `manual_fix_comment` columns and
#' refusing to let two fixes silently touch the same row. This is the repair
#' counterpart to BGmisc's automated [BGmisc::repairIDs()] /
#' [BGmisc::repairSex()]: for the cases a human has to resolve by hand, it keeps
#' the edits reproducible and auditable.
#'
#' Each element of `fixes` is itself a list with three parts:
#' \describe{
#'   \item{rows}{A quoted expression (see [rlang::quo()]) that evaluates within
#'     `ped` to a logical row selector, e.g. `rlang::quo(ID == 348700)`.}
#'   \item{changes}{A named list of `column = new_value` pairs to assign to the
#'     selected rows.}
#'   \item{comment}{A short human-readable note explaining the fix.}
#' }
#'
#' @param ped A pedigree data frame.
#' @param fixes A named list of fixes, each structured as described above. The
#'   names label each fix and are stored in `manual_fix`.
#' @return `ped` with the fixes applied and the `manual_fix` /
#'   `manual_fix_comment` provenance columns populated.
#' @examples
#' \dontrun{
#' fixes <- list(
#'   swap_parents = list(
#'     rows = rlang::quo(ID == 348700),
#'     changes = list(momID = 348701, dadID = NA),
#'     comment = "Verified against parish record."
#'   )
#' )
#' ped <- repairManually(ped, fixes)
#' }
#' @importFrom rlang eval_tidy
#' @export
repairManually <- function(ped, fixes) {
  stopifnot(is.data.frame(ped), is.list(fixes))

  if (!"manual_fix" %in% names(ped)) ped$manual_fix <- NA_character_
  if (!"manual_fix_comment" %in% names(ped)) ped$manual_fix_comment <- NA_character_

  for (fix_name in names(fixes)) {
    fix <- fixes[[fix_name]]

    if (is.null(fix$rows)) {
      stop("Manual fix `", fix_name, "` is missing `rows`.")
    }
    if (is.null(fix$changes) || !is.list(fix$changes)) {
      stop("Manual fix `", fix_name, "` is missing a valid `changes` list.")
    }
    if (is.null(fix$comment)) {
      stop("Manual fix `", fix_name, "` is missing `comment`.")
    }

    rows_to_fix <- rlang::eval_tidy(fix$rows, data = ped)

    if (!is.logical(rows_to_fix) || length(rows_to_fix) != nrow(ped)) {
      stop("Manual fix `", fix_name, "` did not produce a valid logical row selector.")
    }
    rows_to_fix[is.na(rows_to_fix)] <- FALSE

    if (sum(rows_to_fix) == 0) {
      warning("Manual fix `", fix_name, "` matched zero rows.")
      next
    }

    already_fixed <- rows_to_fix & !is.na(ped$manual_fix)
    if (any(already_fixed)) {
      info_cols <- intersect(
        c(
          "manual_fix", "manual_fix_comment",
          "ID", "dadID", "momID", "spID", "byr", "dyr", "sex"
        ),
        names(ped)
      )
      print(ped[already_fixed, info_cols, drop = FALSE])
      stop("Manual fix `", fix_name, "` overlaps with a previous manual fix.")
    }

    for (col in names(fix$changes)) {
      if (!col %in% names(ped)) {
        stop("Manual fix `", fix_name, "` targets missing column `", col, "`.")
      }
      ped[[col]][rows_to_fix] <- fix$changes[[col]]
    }

    ped$manual_fix[rows_to_fix] <- fix_name
    ped$manual_fix_comment[rows_to_fix] <- fix$comment
  }

  ped
}
