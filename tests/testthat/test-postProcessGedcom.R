test_that("processParents adds momID and dadID correctly", {
  # Create a data frame for testing
  df_temp <- data.frame(
    personID = c("I1", "I2", "I3"),
    sex = c("M", "F", "M"),
    FAMS = c("@F1@", "@F1@", NA),
    FAMC = c(NA, NA, "@F1@"),
    stringsAsFactors = FALSE
  )

  # Call processParents
  df_temp <- processParents(df_temp, datasource = "gedcom")

  # Check the structure of the data frame
  expect_true("momID" %in% colnames(df_temp))
  expect_true("dadID" %in% colnames(df_temp))

  # Check the contents of the data frame
  expect_equal(df_temp$momID[1], NA_character_)
  expect_equal(df_temp$dadID[1], NA_character_)
  expect_equal(df_temp$momID[2], NA_character_)
  expect_equal(df_temp$dadID[2], NA_character_)
  expect_equal(df_temp$momID[3], "I2")
  expect_equal(df_temp$dadID[3], "I1")

  # Create a more complex data frame for testing
  df_temp <- data.frame(
    personID = c("I1", "I2", "I3", "I4", "I5"),
    sex = c("M", "F", "M", "F", "M"),
    FAMS = c("@F1@", "@F1@", "@F2@", "@F2@", "@F3@"),
    FAMC = c(NA, NA, "@F1@", "@F1@", "@F2@"),
    stringsAsFactors = FALSE
  )

  # Call processParents
  df_temp <- processParents(df_temp, datasource = "gedcom")

  # Check the contents of the data frame
  expect_equal(df_temp$momID[3], "I2")
  expect_equal(df_temp$dadID[3], "I1")
  expect_equal(df_temp$momID[4], "I2")
  expect_equal(df_temp$dadID[4], "I1")
  expect_equal(df_temp$momID[5], "I4")
  expect_equal(df_temp$dadID[5], "I3")
})

test_that("postProcessGedcom parse_dates = TRUE parses date columns and removes GEDCOM date qualifiers", {
  df_temp <- data.frame(
    personID = "1",
    sex = "M",
    name = "John Doe/",
    name_given = "John",
    name_given_pieces = NA_character_,
    name_surn = "Doe",
    name_surn_pieces = NA_character_,
    birth_date = "ABT 1 JAN 1900",
    death_date = "AFT 31 DEC 2000",
    FAMC = NA_character_,
    FAMS = NA_character_,
    stringsAsFactors = FALSE
  )

  df <- postProcessGedcom(
    df_temp,
    add_parents = FALSE,
    combine_cols = FALSE,
    remove_empty_cols = FALSE,
    parse_dates = TRUE,
    skinny = FALSE
  )

  expect_s3_class(df$birth_date, "Date")
  expect_s3_class(df$death_date, "Date")
  expect_equal(df$birth_date[1], as.Date("1900-01-01"))
  expect_equal(df$death_date[1], as.Date("2000-12-31"))
})

test_that("processParents warns and returns unchanged data when required GEDCOM columns are missing", {
  df_temp <- data.frame(
    personID = c("I1", "I2"),
    sex = c("M", "F"),
    stringsAsFactors = FALSE
  )

  expect_warning(
    out <- processParents(df_temp, datasource = "gedcom"),
    "Missing necessary columns"
  )

  expect_equal(out, df_temp)
})

test_that("processParents rejects invalid datasource values", {
  df_temp <- data.frame(
    personID = "I1",
    sex = "M",
    FAMC = NA_character_,
    FAMS = NA_character_,
    stringsAsFactors = FALSE
  )

  expect_error(
    processParents(df_temp, datasource = "unknown"),
    "Invalid datasource"
  )
})

test_that("mapFAMS2parents warns and returns NULL when required columns are missing", {
  df_temp <- data.frame(
    personID = c("I1", "I2"),
    FAMS = c("F1", "F1"),
    stringsAsFactors = FALSE
  )

  expect_warning(
    out <- mapFAMS2parents(df_temp),
    "necessary columns"
  )

  expect_null(out)
})
