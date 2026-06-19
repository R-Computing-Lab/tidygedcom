library(goodpractice)
checks_sans <- goodpractice::default_checks()[
  !grepl("cyclocomp", goodpractice::default_checks())
]
checks_sans <- checks_sans[!grepl("rcmdcheck", checks_sans)]

# Check the package
gp <- goodpractice::gp(
  checks = checks_sans
)
gp
