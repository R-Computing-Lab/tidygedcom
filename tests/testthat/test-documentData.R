test_that("data loads silently", {
  expect_silent(data(royal92))

})

test_that("royal92 data loads and is checkis_acyclic", {
  require(BGmisc)
  expect_silent(data(royal92,package = "tidygedcom"))

  expect_true(nrow(royal92) == 3010)
  expect_true(nrow(royal92) == max(royal92$personID, na.rm = TRUE))
  expect_true(all(c("personID", "sex", "dadID", "momID","twinID", "name", "famID", "birth_date", "death_date", "title")
  %in% names(royal92)))
  checkis_acyclic <- BGmisc::checkPedigreeNetwork(royal92,
    personID = "personID",
    momID = "momID",
    dadID = "dadID",
    verbose = FALSE
  )
  expect_true(checkis_acyclic$is_acyclic)
})

