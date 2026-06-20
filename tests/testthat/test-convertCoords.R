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
