
test_that("addPersonToPed works as expected", {
  # Initial pedigree data frame
  ped <- data.frame(
    personID = c(1, 2),
    name = c("Alice", "Bob"),
    sex = c("F", "M"),
    momID = c(NA, NA),
    dadID = c(NA, NA),
    twinID = c(NA_integer_, NA_integer_),
    stringsAsFactors = FALSE
  )

  # Add person with all fields specified
  updated <- addPersonToPed(
    ped,
    name = "Charlie",
    sex = "M",
    momID = 1,
    dadID = 2,
    twinID = NA,
    personID = 10,
    overwrite = FALSE
  )

  expect_equal(nrow(updated), 3)
  expect_equal(updated$personID[3], 10)
  expect_equal(updated$name[3], "Charlie")
  expect_equal(updated$sex[3], "M")
  expect_equal(updated$momID[3], 1)
  expect_equal(updated$dadID[3], 2)
  expect_true(is.na(updated$twinID[3]))

  # Add person with generated ID
  updated2 <- addPersonToPed(ped, name = "Dana", sex = "F")
  expect_equal(nrow(updated2), 3)
  expect_equal(updated2$name[3], "Dana")
  expect_equal(updated2$sex[3], "F")
  expect_equal(updated2$personID[3], max(ped$personID, na.rm = TRUE) + 1)

  # Add person with missing optional fields
  updated3 <- addPersonToPed(ped)
  expect_equal(nrow(updated3), 3)
  expect_true(is.na(updated3$name[3]))
  expect_true(is.na(updated3$sex[3]))
  expect_true(is.na(updated3$twinID[3]))
  expect_true(is.na(updated3$momID[3]))
  expect_true(is.na(updated3$dadID[3]))

  expect_equal(updated3$personID[3], max(ped$personID, na.rm = TRUE) + 1)

  # Add person with overwrite = TRUE
  updated4 <- addPersonToPed(ped, name = "New", sex = "F", personID = 1, overwrite = TRUE)
  expect_equal(nrow(updated4), 2)
  expect_equal(updated4$name[1], "New")
  expect_equal(updated4$sex[1], "F")
  expect_equal(updated4$personID[1], 1)
  expect_true(is.na(updated4$momID[1]))
  expect_true(is.na(updated4$dadID[1]))
  expect_true(is.na(updated4$twinID[1]))
  expect_equal(updated4$momID[2], NA)
  expect_equal(updated4$dadID[2], NA)
  expect_equal(updated4$personID[2], 2)
  expect_equal(updated4$name[2], "Bob")
  expect_equal(updated4$sex[2], "M")
  expect_true(is.na(updated4$twinID[2]))
  expect_equal(updated4$twinID[1], NA_integer_)
})

test_that("addPersonToPed works as expected with zygosity", {
  # Initial pedigree data frame
  ped <- data.frame(
    personID = c(1, 2),
    name = c("Alice", "Bob"),
    sex = c("F", "M"),
    momID = c(NA, NA),
    dadID = c(NA, NA),
    twinID = c(NA_integer_, NA_integer_),
    zygosity = c(NA_character_, NA_character_),
    url = NA_character_,
    stringsAsFactors = FALSE
  )

  # Add person with all fields specified
  updated <- addPersonToPed(
    ped,
    name = "Charlie",
    sex = "M",
    momID = 1,
    dadID = 2,
    twinID = NA,
    personID = 10,
    zygosity = NA,
    overwrite = FALSE
  )

  expect_equal(nrow(updated), 3)
  expect_equal(updated$personID[3], 10)
  expect_equal(updated$name[3], "Charlie")
  expect_equal(updated$sex[3], "M")
  expect_equal(updated$momID[3], 1)
  expect_equal(updated$dadID[3], 2)
  expect_true(is.na(updated$twinID[3]))
  expect_true(is.na(updated$zygosity[3]))
  expect_true(is.na(updated$url[3]))

  # Add person with generated ID
  updated2 <- addPersonToPed(ped, name = "Dana", sex = "F", url = "http://example.com")
  expect_equal(nrow(updated2), 3)
  expect_equal(updated2$name[3], "Dana")
  expect_equal(updated2$sex[3], "F")
  expect_equal(updated2$personID[3], max(ped$personID, na.rm = TRUE) + 1)
  expect_true(is.na(updated2$zygosity[3]))
  expect_true(!is.na(updated2$url[3]))

  # Add person with missing optional fields
  updated3 <- addPersonToPed(updated2)
  expect_equal(nrow(updated3), 4)
  expect_true(is.na(updated3$name[4]))
  expect_true(is.na(updated3$sex[4]))
  expect_true(is.na(updated3$twinID[4]))
  expect_true(is.na(updated3$momID[4]))
  expect_true(is.na(updated3$dadID[4]))
  expect_true(is.na(updated3$zygosity[4]))

  expect_equal(updated3$personID[4], max(ped$personID, na.rm = TRUE) + 2)
})


# ─── addPersonToPed – additional paths ───────────────────────────────────────

test_that("addPersonToPed - error when overwrite=TRUE and personID does not exist", {
  ped <- data.frame(
    personID = c(1L, 2L),
    name = c("Alice", "Bob"),
    sex = c("F", "M"),
    momID = c(NA, NA),
    dadID = c(NA, NA),
    twinID = c(NA_integer_, NA_integer_),
    stringsAsFactors = FALSE
  )
  expect_error(
    addPersonToPed(ped, personID = 99, overwrite = TRUE),
    regexp = "does not exist in the pedigree"
  )
})

test_that("addPersonToPed - notes column is handled when present in ped", {
  ped <- data.frame(
    personID = c(1L, 2L),
    name = c("Alice", "Bob"),
    sex = c("F", "M"),
    momID = c(NA, NA),
    dadID = c(NA, NA),
    twinID = c(NA_integer_, NA_integer_),
    notes = c(NA_character_, NA_character_),
    stringsAsFactors = FALSE
  )
  updated <- addPersonToPed(ped,
    name = "Charlie", sex = "M",
    momID = 1, dadID = 2,
    notes = "test note", personID = 10
  )
  expect_equal(nrow(updated), 3)
  expect_equal(updated$notes[3], "test note")

  # When notes not supplied it should be NA
  updated2 <- addPersonToPed(ped, name = "Dana", sex = "F")
  expect_true(is.na(updated2$notes[3]))
})

test_that("addPersonToPed - non-data.frame input raises error", {
  expect_error(
    addPersonToPed(list(personID = 1), personID = 2)
    # stopifnot(is.data.frame(ped)) fires for non-data.frame input
  )
})

