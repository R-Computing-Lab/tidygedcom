test_that("data loads silently", {
  expect_silent(data(royal92))

})

test_that("royal92 data loads and is checkis_acyclic", {
  library(BGmisc)
  expect_silent(data(royal92))
  expect_true(nrow(royal92) > 134)
  expect_true(nrow(royal92) == max(royal92$ID, na.rm = TRUE))
  expect_true(all(c("ID", "sex", "dadID", "momID", "famID", "gen", "proband")
  %in% names(royal92)))
  checkis_acyclic <- BGmisc::checkPedigreeNetwork(royal92,
    personID = "ID",
    momID = "momID",
    dadID = "dadID",
    verbose = FALSE
  )
  expect_true(checkis_acyclic$is_acyclic)
})
