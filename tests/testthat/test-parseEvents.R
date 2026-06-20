birt_no_date_content <- c(
  "0 @I1@ INDI",
  "1 NAME Alice /Jones/",
  "1 SEX F",
  "1 BIRT",
  "2 PLAC Springfield",
  "2 LATI N39.7817",
  "2 LONG W89.6501"
)

birt_no_plac_content <- c(
  "0 @I1@ INDI",
  "1 NAME Bob /Smith/",
  "1 SEX M",
  "1 BIRT",
  "2 DATE 15 MAR 1955"
)

birt_reordered_content <- c(
  "0 @I1@ INDI",
  "1 NAME Carol /Lee/",
  "1 SEX F",
  "1 BIRT",
  "2 LATI N40.7128",
  "2 LONG W74.0060",
  "2 PLAC New York",
  "2 DATE 4 JUL 1976"
)

test_that("processEventLine handles missing DATE gracefully", {
  temp_file <- tempfile(fileext = ".ged")
  writeLines(birt_no_date_content, temp_file)
  df <- readGedcom(temp_file, remove_empty_cols = FALSE)
  expect_true(is.na(df$birth_date[1]))
  expect_equal(df$birth_place[1], "Springfield")
  expect_equal(df$birth_lat[1], "N39.7817")
  expect_equal(df$birth_long[1], "W89.6501")
  unlink(temp_file)
})

test_that("processEventLine handles missing PLAC gracefully", {
  temp_file <- tempfile(fileext = ".ged")
  writeLines(birt_no_plac_content, temp_file)
  df <- readGedcom(temp_file, remove_empty_cols = FALSE)
  expect_equal(df$birth_date[1], "15 MAR 1955")
  expect_true(is.na(df$birth_place[1]))
  unlink(temp_file)
})

test_that("processEventLine handles reordered subfields correctly", {
  temp_file <- tempfile(fileext = ".ged")
  writeLines(birt_reordered_content, temp_file)
  df <- readGedcom(temp_file)
  expect_equal(df$birth_date[1], "4 JUL 1976")
  expect_equal(df$birth_place[1], "New York")
  expect_equal(df$birth_lat[1], "N40.7128")
  expect_equal(df$birth_long[1], "W74.0060")
  unlink(temp_file)
})
