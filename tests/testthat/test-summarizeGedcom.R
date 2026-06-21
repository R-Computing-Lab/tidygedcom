make_df <- function(...) {
  data.frame(..., stringsAsFactors = FALSE)
}

base_df <- make_df(
  personID = c("1", "2", "3", "4", "5"),
  sex          = c("F", "M", "M", "F", NA),
  birth_date   = c("1 JAN 1900", NA, "5 MAR 1910", NA, "2 FEB 1920"),
  death_date   = c(NA, "3 APR 1980", NA, NA, NA),
  chr_date     = c(NA, NA, NA, "10 JUN 1960", NA),
  burial_date  = c(NA, NA, NA, NA, NA),
  birth_place  = c("London", NA, "Paris", NA, "Berlin"),
  death_place  = c(NA, "Rome", NA, NA, NA),
  momID        = c(NA, NA, NA,"1", "1"),
  dadID        = c(NA, NA, NA, "2", "2")
)

# ---------------------------------------------------------------------------
# summarizeGedcom — return value structure
# ---------------------------------------------------------------------------

test_that("summarizeGedcom returns a tidygedcom_summary object", {
  s <- summarizeGedcom(base_df)
  expect_s3_class(s, "tidygedcom_summary")
})

test_that("summarizeGedcom errors on non-data-frame input", {
  expect_error(summarizeGedcom("not a df"))
})

# ---------------------------------------------------------------------------
# Individual counts
# ---------------------------------------------------------------------------

test_that("summarizeGedcom counts total individuals", {
  s <- summarizeGedcom(base_df)
  expect_equal(s$n_individuals, 5L)
})

test_that("summarizeGedcom counts sex correctly", {
  s <- summarizeGedcom(base_df)
  expect_equal(s$n_male, 2L)
  expect_equal(s$n_female, 2L)
  expect_equal(s$n_unknown_sex, 1L)
})

test_that("summarizeGedcom returns NA sex counts when sex column absent", {
  df <- make_df(birth_date = c("1 JAN 1900", NA))
  s <- summarizeGedcom(df)
  expect_true(is.na(s$n_male))
  expect_true(is.na(s$n_female))
  expect_true(is.na(s$n_unknown_sex))
})

# ---------------------------------------------------------------------------
# Event date / place coverage
# ---------------------------------------------------------------------------

test_that("summarizeGedcom counts birth dates", {
  s <- summarizeGedcom(base_df)
  expect_equal(s$n_with_birth_date, 3L)
})

test_that("summarizeGedcom counts death dates", {
  s <- summarizeGedcom(base_df)
  expect_equal(s$n_with_death_date, 1L)
})

test_that("summarizeGedcom counts christening dates", {
  s <- summarizeGedcom(base_df)
  expect_equal(s$n_with_chr_date, 1L)
})

test_that("summarizeGedcom counts burial dates as zero when all NA", {
  s <- summarizeGedcom(base_df)
  expect_equal(s$n_with_burial_date, 0L)
})

test_that("summarizeGedcom counts birth and death places", {
  s <- summarizeGedcom(base_df)
  expect_equal(s$n_with_birth_place, 3L)
  expect_equal(s$n_with_death_place, 1L)
})

test_that("summarizeGedcom returns NA for absent optional columns", {
  df <- make_df(sex = c("M", "F"))
  s <- summarizeGedcom(df)
  expect_true(is.na(s$n_with_birth_date))
  expect_true(is.na(s$n_with_death_date))
  expect_true(is.na(s$n_with_birth_place))
})

# ---------------------------------------------------------------------------
# Parent linkage
# ---------------------------------------------------------------------------

test_that("summarizeGedcom counts individuals with known mother", {
  s <- summarizeGedcom(base_df)
  expect_equal(s$n_with_mom, 2L)
})

test_that("summarizeGedcom counts individuals with known father", {
  s <- summarizeGedcom(base_df)
  expect_equal(s$n_with_dad, 2L)
})

# ---------------------------------------------------------------------------
# gedcom_version attribute
# ---------------------------------------------------------------------------

test_that("summarizeGedcom passes through gedcom_version attribute", {
  df <- base_df
  attr(df, "gedcom_version") <- "5.5.1"
  s <- summarizeGedcom(df)
  expect_equal(s$gedcom_version, "5.5.1")
})

test_that("summarizeGedcom stores NULL when gedcom_version attribute absent", {
  df <- make_df(sex = "M")
  s <- summarizeGedcom(df)
  expect_null(s$gedcom_version)
})

# ---------------------------------------------------------------------------
# print.tidygedcom_summary
# ---------------------------------------------------------------------------

test_that("print.tidygedcom_summary produces output", {
  s <- summarizeGedcom(base_df)
  expect_output(print(s), "GEDCOM Summary")
})

test_that("print.tidygedcom_summary shows individual count", {
  s <- summarizeGedcom(base_df)
  expect_output(print(s), "Individuals: 5")
})

test_that("print.tidygedcom_summary shows sex breakdown", {
  s <- summarizeGedcom(base_df)
  expect_output(print(s), "M = 2")
})

test_that("print.tidygedcom_summary returns invisibly", {
  s <- summarizeGedcom(base_df)
  ret <- withVisible(print(s))
  expect_false(ret$visible)
})

test_that("print.tidygedcom_summary shows 'unknown' version when absent", {
  df <- make_df(sex = "M")
  s <- summarizeGedcom(df)
  expect_output(print(s), "unknown")
})
