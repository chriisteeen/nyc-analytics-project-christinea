# Prepare NASA exoplanet data for analysis

nasa_raw <- read.csv(
  "data/raw/nasa_pscomppars_2026-09-19.csv",
  na.strings = c("", "NA", "null"),
  stringsAsFactors = FALSE
)

# Create a working copy for cleaning
nasa_clean <- nasa_raw

# Confirm rows and columns
dim(nasa_clean)

# Review column types
str(nasa_clean)

# Text columns that may contain extra spaces
text_columns <- c(
  "pl_name",
  "hostname",
  "gaia_dr3_id",
  "pl_bmassprov",
  "st_spectype",
  "discoverymethod",
  "disc_facility",
  "disc_telescope",
  "disc_instrument"
)

# Remove unnecessary spaces
nasa_clean[text_columns] <- lapply(
  nasa_clean[text_columns],
  trimws
)

# Check for duplicate rows and planet names
sum(duplicated(nasa_clean))
sum(duplicated(nasa_clean$pl_name))

# Remove exact duplicate rows
nasa_clean <- nasa_clean[!duplicated(nasa_clean), ]

# Summarize missing values in every column
missing_summary <- data.frame(
  variable = names(nasa_clean),
  missing_count = sapply(nasa_clean, function(x) sum(is.na(x))),
  missing_percent = round(
    sapply(nasa_clean, function(x) mean(is.na(x)) * 100),
    2
  )
)

# Show columns with the most missing data first
missing_summary <- missing_summary[
  order(-missing_summary$missing_percent),
]

missing_summary

# Identify planets with all required ESI inputs
nasa_clean$esi_ready <- complete.cases(
  nasa_clean[c(
    "pl_rade", "pl_bmasse", "pl_dens", "pl_eqt"
  )]
)

# Count how many planets are ready for ESI calculation
sum(nasa_clean$esi_ready)

write.csv(
  nasa_clean,
  "data/processed/nasa_clean.csv",
  row.names = FALSE
)
file.exists("data/processed/nasa_clean.csv")

