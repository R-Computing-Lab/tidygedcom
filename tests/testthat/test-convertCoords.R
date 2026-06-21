test_that("gedcomLat2Numeric converts N/S notation correctly", {
  expect_equal(gedcomLat2Numeric("N51.5074"), 51.5074)
  expect_equal(gedcomLat2Numeric("S33.8688"), -33.8688)
  expect_true(is.na(gedcomLat2Numeric(NA_character_)))
})

test_that("gedcomLon2Numeric converts E/W notation correctly", {
  expect_equal(gedcomLon2Numeric("E151.2093"), 151.2093)
  expect_equal(gedcomLon2Numeric("W0.1278"), -0.1278)
  expect_true(is.na(gedcomLon2Numeric(NA_character_)))
})

test_that("gedcomLat2Numeric returns NA for unrecognised prefix", {
  expect_true(is.na(gedcomLat2Numeric("12.34")))
  expect_true(is.na(gedcomLat2Numeric("")))
})

test_that("gedcomLon2Numeric returns NA for unrecognised prefix", {
  expect_true(is.na(gedcomLon2Numeric("12.34")))
  expect_true(is.na(gedcomLon2Numeric("")))
})

# ---------------------------------------------------------------------------
# Vector inputs
# ---------------------------------------------------------------------------

test_that("gedcomLat2Numeric handles a mixed vector", {
  result <- gedcomLat2Numeric(c("N51.5074", "S33.8688", NA, "bad"))
  expect_equal(result, c(51.5074, -33.8688, NA_real_, NA_real_))
})

test_that("gedcomLon2Numeric handles a mixed vector", {
  result <- gedcomLon2Numeric(c("E151.2093", "W0.1278", NA, "bad"))
  expect_equal(result, c(151.2093, -0.1278, NA_real_, NA_real_))
})

test_that("gedcomLat2Numeric handles zero latitude", {
  expect_equal(gedcomLat2Numeric("N0"), 0)
  expect_equal(gedcomLat2Numeric("S0"), 0)
})

test_that("gedcomLon2Numeric handles zero longitude", {
  expect_equal(gedcomLon2Numeric("E0"), 0)
  expect_equal(gedcomLon2Numeric("W0"), 0)
})

test_that("gedcomLat2Numeric output length matches input length", {
  x <- c("N10.0", "S20.0", NA, "bad", "N30.0")
  expect_length(gedcomLat2Numeric(x), length(x))
})

test_that("gedcomLon2Numeric output length matches input length", {
  x <- c("E10.0", "W20.0", NA, "bad", "E30.0")
  expect_length(gedcomLon2Numeric(x), length(x))
})

# ---------------------------------------------------------------------------
# convertGedcomCoords
# ---------------------------------------------------------------------------

test_that("convertGedcomCoords converts _lat and _long columns automatically", {
  df <- data.frame(
    birth_lat  = "N51.5074",
    birth_long = "W0.1278",
    name       = "Alice",
    stringsAsFactors = FALSE
  )
  result <- convertGedcomCoords(df)
  expect_equal(result$birth_lat, 51.5074)
  expect_equal(result$birth_long, -0.1278)
  expect_equal(result$name, "Alice")
})

test_that("convertGedcomCoords converts multiple coordinate column pairs", {
  df <- data.frame(
    birth_lat  = "N51.5074",
    birth_long = "W0.1278",
    death_lat  = "S33.8688",
    death_long = "E151.2093",
    stringsAsFactors = FALSE
  )
  result <- convertGedcomCoords(df)
  expect_equal(result$birth_lat,   51.5074)
  expect_equal(result$birth_long,  -0.1278)
  expect_equal(result$death_lat,  -33.8688)
  expect_equal(result$death_long, 151.2093)
})

test_that("convertGedcomCoords respects explicit lat_cols and long_cols", {
  df <- data.frame(
    my_latitude  = "N40.7128",
    my_longitude = "W74.0060",
    stringsAsFactors = FALSE
  )
  result <- convertGedcomCoords(df,
    lat_cols  = "my_latitude",
    long_cols = "my_longitude"
  )
  expect_equal(result$my_latitude,   40.7128)
  expect_equal(result$my_longitude, -74.0060)
})

test_that("convertGedcomCoords leaves non-coordinate columns unchanged", {
  df <- data.frame(
    birth_lat  = "N10.0",
    birth_long = "E20.0",
    id         = 99L,
    stringsAsFactors = FALSE
  )
  result <- convertGedcomCoords(df)
  expect_equal(result$id, 99L)
})

test_that("convertGedcomCoords handles NA values in coordinate columns", {
  df <- data.frame(
    birth_lat  = NA_character_,
    birth_long = NA_character_,
    stringsAsFactors = FALSE
  )
  result <- convertGedcomCoords(df)
  expect_true(is.na(result$birth_lat))
  expect_true(is.na(result$birth_long))
})
