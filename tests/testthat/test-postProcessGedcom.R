test_that("parse_dates imputes a day for month-precision dates", {
  ged <- c(
    "0 @I1@ INDI",
    "1 NAME Martha Law /Segraves/",
    "1 SEX F",
    "1 BIRT",
    "2 DATE Oct 1814"
  )
  temp_file <- tempfile(fileext = ".ged")
  writeLines(ged, temp_file)
  on.exit(unlink(temp_file), add = TRUE)

  df <- readGedcom(temp_file, parse_dates = TRUE, verbose = FALSE)

  # Mid-month is the minimum-expected-error choice for an unknown day.
  expect_equal(df$birth_date[1], as.Date("1814-10-15"))
})

test_that("parse_dates imputes month and day for year-precision dates", {
  ged <- c(
    "0 @I1@ INDI",
    "1 NAME William Pitt /Waugh/ Jr",
    "1 SEX M",
    "1 BIRT",
    "2 DATE 1844",
    "0 @I2@ INDI",
    "1 NAME W. Henderson /Waugh/",
    "1 SEX M",
    "1 BIRT",
    "2 DATE abt 1835"
  )
  temp_file <- tempfile(fileext = ".ged")
  writeLines(ged, temp_file)
  on.exit(unlink(temp_file), add = TRUE)

  df <- readGedcom(temp_file, parse_dates = TRUE, verbose = FALSE)

  expect_equal(df$birth_date[1], as.Date("1844-06-15"))
  # Qualifiers are stripped before the year is read.
  expect_equal(df$birth_date[2], as.Date("1835-06-15"))
})

test_that("parse_dates strips qualifiers written with a trailing period", {
  # Ancestry.com exports write these as "Abt." and "Aft.", not "ABT"/"AFT".
  ged <- c(
    "0 @I1@ INDI",
    "1 NAME W. Henderson /Waugh/",
    "1 SEX M",
    "1 BIRT",
    "2 DATE Abt. Jun 1880",
    "1 DEAT",
    "2 DATE Aft. Oct 1896"
  )
  temp_file <- tempfile(fileext = ".ged")
  writeLines(ged, temp_file)
  on.exit(unlink(temp_file), add = TRUE)

  df <- readGedcom(temp_file, parse_dates = TRUE, verbose = FALSE)

  expect_equal(df$birth_date[1], as.Date("1880-06-15"))
  expect_equal(df$death_date[1], as.Date("1896-10-15"))
})

test_that("qualifier stripping does not truncate ordinary words", {
  expect_equal(
    stripDateQualifiers(c("before the war", "Abt. 1850", "bet 1840")),
    c("before the war", "1850", "1840")
  )
})

test_that("parse_dates leaves full dates untouched and can skip imputation", {
  ged <- c(
    "0 @I1@ INDI",
    "1 NAME William Pitt /Waugh/",
    "1 SEX M",
    "1 BIRT",
    "2 DATE 28 April 1775",
    "0 @I2@ INDI",
    "1 NAME Matilda /Grinton/",
    "1 SEX F",
    "1 BIRT",
    "2 DATE abt 1797"
  )
  temp_file <- tempfile(fileext = ".ged")
  writeLines(ged, temp_file)
  on.exit(unlink(temp_file), add = TRUE)

  full <- readGedcom(temp_file, parse_dates = TRUE, verbose = FALSE)
  expect_equal(full$birth_date[1], as.Date("1775-04-28"))

  # Opting out restores the stricter behaviour: partial dates become NA.
  strict <- readGedcom(temp_file,
    parse_dates = TRUE,
    impute_partial_dates = FALSE, verbose = FALSE
  )
  expect_equal(strict$birth_date[1], as.Date("1775-04-28"))
  expect_true(is.na(strict$birth_date[2]))
})

test_that("mapFAMS2parents tolerates a spouse with missing sex", {
  # A GEDCOM record with no `1 SEX` line yields NA, which must be skipped
  # rather than compared, since `if (NA == "M")` is a hard error.
  df_temp <- data.frame(
    personID = c("I1", "I2", "I3"),
    sex = c("M", NA_character_, "M"),
    FAMS = c("@F1@", "@F1@", NA),
    FAMC = c(NA, NA, "@F1@"),
    stringsAsFactors = FALSE
  )

  expect_no_error(parents <- mapFAMS2parents(df_temp))

  # The known father is still recorded; the unknown-sex spouse is simply absent.
  expect_equal(parents[["@F1@"]]$father, "I1")
  expect_null(parents[["@F1@"]]$mother)
})

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

test_that("date qualifiers are stripped", {
expect_equal(
    stripDateQualifiers(c("ABT 1835", "Aft. Oct 1896")),
    c("1835", "Oct 1896")
  )
})

test_that("partial dates are imputed", {
expect_equal(
    imputePartialDates(c("Oct 1814", "1844", "28 Apr 1775", NA)),
    c("15 Oct 1814", "15 JUN 1844", "28 Apr 1775", NA)
  )
})
