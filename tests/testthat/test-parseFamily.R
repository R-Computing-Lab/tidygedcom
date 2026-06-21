minimal_fam_lines <- c(
  "0 HEAD",
  "0 @F1@ FAM",
  "1 HUSB @I1@",
  "1 WIFE @I2@",
  "1 CHIL @I3@",
  "1 MARR",
  "2 DATE 12 JUN 1980",
  "2 PLAC London",
  "0 TRLR"
)

two_fam_lines <- c(
  "0 HEAD",
  "0 @F1@ FAM",
  "1 HUSB @I1@",
  "1 WIFE @I2@",
  "1 MARR",
  "2 DATE 1 JAN 1990",
  "2 PLAC Paris",
  "0 @F2@ FAM",
  "1 HUSB @I4@",
  "1 CHIL @I5@",
  "1 CHIL @I6@",
  "1 DIV",
  "2 DATE 15 MAR 2001",
  "2 PLAC Berlin",
  "0 TRLR"
)

# ---------------------------------------------------------------------------
# splitFamilies
# ---------------------------------------------------------------------------

test_that("splitFamilies returns empty list when no FAM records", {
  lines <- c("0 HEAD", "0 @I1@ INDI", "0 TRLR")
  expect_equal(splitFamilies(lines), list())
})

test_that("splitFamilies returns one block for a single FAM", {
  blocks <- splitFamilies(minimal_fam_lines)
  expect_length(blocks, 1L)
  expect_true(grepl("@ FAM", blocks[[1]][1]))
})

test_that("splitFamilies returns two blocks for two FAMs", {
  blocks <- splitFamilies(two_fam_lines)
  expect_length(blocks, 2L)
})

test_that("splitFamilies block does not bleed into next record", {
  blocks <- splitFamilies(two_fam_lines)
  expect_false(any(grepl("@F2@", blocks[[1]])))
})

# ---------------------------------------------------------------------------
# parseFamilyBlock
# ---------------------------------------------------------------------------

test_that("parseFamilyBlock extracts famID, husbID, wifeID, childID", {
  block <- c(
    "0 @F1@ FAM",
    "1 HUSB @I10@",
    "1 WIFE @I20@",
    "1 CHIL @I30@"
  )
  result <- parseFamilyBlock(block)
  expect_equal(result$famID, "1")
  expect_equal(result$husbID, "10")
  expect_equal(result$wifeID, "20")
  expect_equal(result$children, "30")
})

test_that("parseFamilyBlock concatenates multiple children", {
  block <- c(
    "0 @F2@ FAM",
    "1 HUSB @I1@",
    "1 CHIL @I3@",
    "1 CHIL @I4@",
    "1 CHIL @I5@"
  )
  result <- parseFamilyBlock(block)
  expect_equal(result$children, "3, 4, 5")
})

test_that("parseFamilyBlock returns NULL for block with no numeric ID", {
  block <- c("0 @ FAM", "1 HUSB @I1@")
  expect_null(parseFamilyBlock(block))
})

test_that("parseFamilyBlock captures marriage date and place", {
  block <- c(
    "0 @F1@ FAM",
    "1 MARR",
    "2 DATE 12 JUN 1980",
    "2 PLAC London"
  )
  result <- parseFamilyBlock(block)
  expect_equal(result$marr_date, "12 JUN 1980")
  expect_equal(result$marr_place, "London")
})

test_that("parseFamilyBlock captures divorce date and place", {
  block <- c(
    "0 @F1@ FAM",
    "1 DIV",
    "2 DATE 5 APR 2005",
    "2 PLAC Chicago"
  )
  result <- parseFamilyBlock(block)
  expect_equal(result$div_date, "5 APR 2005")
  expect_equal(result$div_place, "Chicago")
})

test_that("parseFamilyBlock leaves missing fields as NA", {
  block <- c("0 @F3@ FAM")
  result <- parseFamilyBlock(block)
  expect_true(is.na(result$husbID))
  expect_true(is.na(result$wifeID))
  expect_true(is.na(result$children))
  expect_true(is.na(result$marr_date))
  expect_true(is.na(result$div_date))
})

# ---------------------------------------------------------------------------
# readGedcomFamilies
# ---------------------------------------------------------------------------

test_that("readGedcomFamilies returns NULL with warning for missing FAM records", {
  tmp <- tempfile(fileext = ".ged")
  writeLines(c("0 HEAD", "0 @I1@ INDI", "0 TRLR"), tmp)
  expect_warning(result <- readGedcomFamilies(tmp), "No family records")
  expect_null(result)
  unlink(tmp)
})

test_that("readGedcomFamilies stops for nonexistent file", {
  expect_error(readGedcomFamilies("nonexistent_file.ged"), "File does not exist")
})

test_that("readGedcomFamilies parses a single family correctly", {
  tmp <- tempfile(fileext = ".ged")
  writeLines(minimal_fam_lines, tmp)
  df <- readGedcomFamilies(tmp, remove_empty_cols = FALSE)
  expect_equal(nrow(df), 1L)
  expect_equal(df$famID, "1")
  expect_equal(df$husbID, "1")
  expect_equal(df$wifeID, "2")
  expect_equal(df$children, "3")
  expect_equal(df$marr_date, "12 JUN 1980")
  expect_equal(df$marr_place, "London")
  unlink(tmp)
})

test_that("readGedcomFamilies parses two families, one row each", {
  tmp <- tempfile(fileext = ".ged")
  writeLines(two_fam_lines, tmp)
  df <- readGedcomFamilies(tmp)
  expect_equal(nrow(df), 2L)
  unlink(tmp)
})

test_that("readGedcomFamilies remove_empty_cols drops all-NA columns", {
  tmp <- tempfile(fileext = ".ged")
  writeLines(minimal_fam_lines, tmp)
  df_full <- readGedcomFamilies(tmp, remove_empty_cols = FALSE)
  df_trim <- readGedcomFamilies(tmp, remove_empty_cols = TRUE)
  expect_true(ncol(df_trim) <= ncol(df_full))
  unlink(tmp)
})

test_that("readGedcomFamilies parse_dates converts marr_date to Date", {
  tmp <- tempfile(fileext = ".ged")
  writeLines(minimal_fam_lines, tmp)
  df <- readGedcomFamilies(tmp, parse_dates = TRUE, remove_empty_cols = FALSE)
  expect_s3_class(df$marr_date, "Date")
  expect_equal(df$marr_date, as.Date("1980-06-12"))
  unlink(tmp)
})

test_that("readGedcomFamilies parse_dates strips GEDCOM calendar escape", {
  lines <- c(
    "0 HEAD",
    "0 @F1@ FAM",
    "1 MARR",
    "2 DATE @#DGREGORIAN@ 12 JUN 1980",
    "0 TRLR"
  )
  tmp <- tempfile(fileext = ".ged")
  writeLines(lines, tmp)
  df <- readGedcomFamilies(tmp, parse_dates = TRUE, remove_empty_cols = FALSE)
  expect_s3_class(df$marr_date, "Date")
  expect_equal(df$marr_date, as.Date("1980-06-12"))
  unlink(tmp)
})

test_that("readGedcomFamilies captures divorce info in second family", {
  tmp <- tempfile(fileext = ".ged")
  writeLines(two_fam_lines, tmp)
  df <- readGedcomFamilies(tmp, remove_empty_cols = FALSE)
  expect_equal(df$div_date[2], "15 MAR 2001")
  expect_equal(df$div_place[2], "Berlin")
  unlink(tmp)
})
