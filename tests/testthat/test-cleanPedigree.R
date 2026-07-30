# ---------------------------------------------------------------------------
# sliceByID
# ---------------------------------------------------------------------------

test_that("sliceByID returns self, parent, and spouse rows", {
  ped <- data.frame(
    ID = c(1, 2, 3, 4, 5),
    momID = c(NA, NA, 2, 2, NA),
    dadID = c(NA, NA, 1, 1, NA),
    spID = c(2, 1, NA, 5, 4),
    stringsAsFactors = FALSE
  )
  # 1 appears as ID (row 1), as dadID (rows 3, 4), and as spID (row 2)
  res <- sliceByID(ped, ID = 1)
  expect_setequal(res$ID, c(1, 2, 3, 4))
})

test_that("sliceByID accepts multiple IDs", {
  ped <- data.frame(
    ID = c(1, 2, 3),
    momID = c(NA, NA, 2),
    dadID = c(NA, NA, 1),
    spID = c(2, 1, NA),
    stringsAsFactors = FALSE
  )
  res <- sliceByID(ped, ID = c(1, 2))
  expect_setequal(res$ID, c(1, 2, 3))
})

test_that("sliceByID recognises non-canonical column names via the standardiser", {
  ped_var <- data.frame(
    personID = c(1, 2, 3),
    pid_moth = c(NA, NA, 2),
    pid_fath = c(NA, NA, 1),
    pid_spouse1 = c(2, 1, NA),
    stringsAsFactors = FALSE
  )
  res <- sliceByID(ped_var, ID = 1)
  # 1 is self (row 1), father of row 3, and spouse of row 2
  expect_setequal(res$personID, c(1, 2, 3))
})

test_that("sliceByID preserves the caller's original column names", {
  ped_var <- data.frame(
    personID = c(1, 2, 3),
    pid_fath = c(NA, NA, 1),
    pid_spouse1 = c(2, 1, NA),
    stringsAsFactors = FALSE
  )
  res <- sliceByID(ped_var, ID = 1)
  expect_true(all(c("personID", "pid_fath", "pid_spouse1") %in% names(res)))
  expect_false(any(c("ID", "dadID", "spID") %in% names(res)))
})

test_that("sliceByID searches extra (multi-)spouse columns", {
  ped_ms <- data.frame(
    ID = c(1, 2, 3),
    spID = c(2, 1, NA),
    spID2 = c(3, NA, 1),
    stringsAsFactors = FALSE
  )
  # 3 is self (row 3) and second spouse of row 1
  res <- sliceByID(ped_ms, ID = 3)
  expect_setequal(res$ID, c(1, 3))
})

test_that("sliceByID errors when no linking columns are present", {
  df <- data.frame(name = c("a", "b"), byr = c(1900, 1901), stringsAsFactors = FALSE)
  expect_error(sliceByID(df, ID = 1), "linking columns")
})

# ---------------------------------------------------------------------------
# findIDs
# ---------------------------------------------------------------------------

test_that("findIDs locates an ID across datasets and columns", {
  dl <- list(
    a = data.frame(ID = c(10, 11), dadID = c(NA, 10), stringsAsFactors = FALSE),
    b = data.frame(ID = c(10, 20), momID = c(NA, 10), stringsAsFactors = FALSE)
  )
  res <- findIDs(dl, ID = 10)
  expect_equal(nrow(res), 4)
  expect_true(all(res$matched_id == "10"))
  expect_setequal(res$dataset, c("a", "b"))
  expect_setequal(res$matched_column, c("ID", "dadID", "momID"))
})

test_that("findIDs returns zero rows when nothing matches", {
  dl <- list(a = data.frame(ID = c(1, 2), stringsAsFactors = FALSE))
  res <- findIDs(dl, ID = 999)
  expect_equal(nrow(res), 0)
})

test_that("findIDs carries context columns through", {
  dl <- list(x = data.frame(ID = c(1, 2), sex = c("M", "F"), stringsAsFactors = FALSE))
  res <- findIDs(dl, ID = 1)
  expect_true("sex" %in% names(res))
  expect_equal(res$sex, "M")
})

test_that("findIDs only searches ID-like columns unless include_all_id_cols", {
  dl <- list(x = data.frame(ID = c(1, 2), note = c(99, 1), stringsAsFactors = FALSE))

  res_default <- findIDs(dl, ID = 1)
  expect_setequal(res_default$matched_column, "ID")

  res_all <- findIDs(dl, ID = 1, include_all_id_cols = TRUE)
  expect_true("note" %in% res_all$matched_column)
})

test_that("findIDs requires a named list", {
  expect_error(findIDs(list(data.frame(ID = 1)), ID = 1))
})

# ---------------------------------------------------------------------------
# summarizeIDs / summariseIDs
# ---------------------------------------------------------------------------

test_that("summarizeIDs counts matches per id, dataset, and column", {
  dl <- list(
    a = data.frame(ID = c(10, 11), dadID = c(NA, 10), stringsAsFactors = FALSE),
    b = data.frame(ID = c(10, 20), momID = c(NA, 10), stringsAsFactors = FALSE)
  )
  s <- summarizeIDs(dl, ID = 10)
  expect_true(all(c("matched_id", "dataset", "matched_column", "n_matches") %in% names(s)))
  expect_equal(sum(s$n_matches), 4)
})

test_that("summariseIDs is an alias for summarizeIDs", {
  dl <- list(a = data.frame(ID = c(10, 11), dadID = c(NA, 10), stringsAsFactors = FALSE))
  expect_identical(summariseIDs(dl, 10), summarizeIDs(dl, 10))
})

# ---------------------------------------------------------------------------
# repairManually
# ---------------------------------------------------------------------------

test_that("repairManually applies changes and records provenance", {
  demo <- data.frame(
    ID = c(1, 2, 3), momID = c(NA, NA, NA), sex = c("F", "M", "F"),
    stringsAsFactors = FALSE
  )
  fixes <- list(
    fix_mom = list(rows = rlang::quo(ID == 3), changes = list(momID = 1), comment = "verified")
  )
  out <- repairManually(demo, fixes)

  expect_equal(out$momID[out$ID == 3], 1)
  expect_equal(out$manual_fix[out$ID == 3], "fix_mom")
  expect_equal(out$manual_fix_comment[out$ID == 3], "verified")
  expect_true(is.na(out$manual_fix[out$ID == 1]))
})

test_that("repairManually creates the provenance columns when absent", {
  demo <- data.frame(ID = 1:2, sex = c("F", "M"), stringsAsFactors = FALSE)
  fixes <- list(
    f = list(rows = rlang::quo(ID == 1), changes = list(sex = "M"), comment = "c")
  )
  out <- repairManually(demo, fixes)
  expect_true(all(c("manual_fix", "manual_fix_comment") %in% names(out)))
})

test_that("repairManually errors when two fixes touch the same row", {
  demo <- data.frame(ID = 1:3, sex = c("F", "M", "F"), stringsAsFactors = FALSE)
  fixes <- list(
    a = list(rows = rlang::quo(ID %in% c(1, 2)), changes = list(sex = "X"), comment = "c1"),
    b = list(rows = rlang::quo(ID == 2), changes = list(sex = "Y"), comment = "c2")
  )
  expect_error(repairManually(demo, fixes), "overlaps")
})

test_that("repairManually warns on a zero-match fix", {
  demo <- data.frame(ID = 1:3, sex = c("F", "M", "F"), stringsAsFactors = FALSE)
  fixes <- list(
    z = list(rows = rlang::quo(ID == 999), changes = list(sex = "Z"), comment = "c")
  )
  expect_warning(repairManually(demo, fixes), "zero rows")
})

test_that("repairManually validates each fix's structure", {
  demo <- data.frame(ID = 1:2, sex = c("F", "M"), stringsAsFactors = FALSE)

  expect_error(
    repairManually(demo, list(bad = list(changes = list(sex = "X"), comment = "c"))),
    "rows"
  )
  expect_error(
    repairManually(demo, list(bad = list(rows = rlang::quo(ID == 1), comment = "c"))),
    "changes"
  )
  expect_error(
    repairManually(demo, list(bad = list(rows = rlang::quo(ID == 1), changes = list(sex = "X")))),
    "comment"
  )
})

test_that("repairManually errors on a missing target column", {
  demo <- data.frame(ID = 1:2, sex = c("F", "M"), stringsAsFactors = FALSE)
  fixes <- list(
    bad = list(rows = rlang::quo(ID == 1), changes = list(nope = 5), comment = "c")
  )
  expect_error(repairManually(demo, fixes), "missing column")
})

test_that("repairManually rejects a non-logical row selector", {
  demo <- data.frame(ID = 1:2, sex = c("F", "M"), stringsAsFactors = FALSE)
  fixes <- list(
    bad = list(rows = rlang::quo(ID), changes = list(sex = "X"), comment = "c")
  )
  expect_error(repairManually(demo, fixes), "valid logical")
})
