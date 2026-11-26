# Download NASA exoplanet data for Team R&P

columns <- c(
  "pl_name",
  "hostname",
  "gaia_dr3_id",
  "pl_rade",
  "pl_bmasse",
  "pl_bmassprov",
  "pl_dens",
  "pl_eqt",
  "st_teff",
  "st_mass",
  "st_rad",
  "st_lum",
  "st_spectype",
  "sy_dist",
  "sy_gaiamag",
  "pl_trandep",
  "disc_year",
  "discoverymethod",
  "disc_facility",
  "disc_telescope",
  "disc_instrument"
)

query <- paste0(
  "select+",
  paste(columns, collapse = ","),
  "+from+pscomppars"
)

nasa_url <- paste0(
  "https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=",
  query,
  "&format=csv"
)

exoplanets <- read.csv(
  nasa_url,
  na.strings = c("", "null")
)

dir.create(
  "data/raw",
  recursive = TRUE,
  showWarnings = FALSE
)

file_name <- paste0(
  "data/raw/nasa_pscomppars_",
  Sys.Date(),
  ".csv"
)

write.csv(
  exoplanets,
  file_name,
  row.names = FALSE
)

cat(
  "Downloaded", nrow(exoplanets), "confirmed exoplanets.\n",
  "Saved to:", file_name, "\n"
)
