# Calculate adapted Earth Similarity Index

# Import cleaned NASA data
esi_data <- read.csv(
  "data/processed/nasa_clean.csv",
  stringsAsFactors = FALSE
)

# Similarity-score function
similarity_score <- function(x, earth_value, weight) {
  (
    1 - abs((x - earth_value) / (x + earth_value))
  ) ^ weight
}

# Identify planets with all four required inputs
esi_data$esi_eligible <- complete.cases(
  esi_data[c(
    "pl_rade",
    "pl_bmasse",
    "pl_dens",
    "pl_eqt"
  )]
)

# Calculate escape velocity relative to Earth
esi_data$escape_velocity_ratio <- sqrt(
  esi_data$pl_bmasse / esi_data$pl_rade
)

# Record the sources of density and temperature
esi_data$density_source <- ifelse(
  !is.na(esi_data$pl_dens),
  "NASA archive value",
  NA
)

esi_data$temperature_proxy_k <- esi_data$pl_eqt

esi_data$temperature_method <- ifelse(
  !is.na(esi_data$pl_eqt),
  "NASA equilibrium temperature used as proxy",
  NA
)

# Calculate the four ESI components
esi_data$esi_radius <- similarity_score(
  esi_data$pl_rade,
  1,
  0.57
)

esi_data$esi_density <- similarity_score(
  esi_data$pl_dens,
  5.514,
  1.07
)

esi_data$esi_escape <- similarity_score(
  esi_data$escape_velocity_ratio,
  1,
  0.70
)

esi_data$esi_temperature <- similarity_score(
  esi_data$temperature_proxy_k,
  288,
  5.58
)

# Calculate overall adapted ESI
esi_data$esi <- (
  esi_data$esi_radius *
    esi_data$esi_density *
    esi_data$esi_escape *
    esi_data$esi_temperature
) ^ (1 / 4)

# Classify high-ESI planets
esi_data$high_esi <- (
  !is.na(esi_data$esi) &
    esi_data$esi >= 0.80
)

# Explain why an ESI was not calculated
esi_data$esi_exclusion_reason <- ifelse(
  esi_data$esi_eligible,
  NA,
  "Missing one or more required ESI inputs"
)

# Select useful output columns
esi_results <- esi_data[c(
  "pl_name",
  "hostname",
  "gaia_dr3_id",
  "pl_rade",
  "pl_bmasse",
  "pl_bmassprov",
  "pl_dens",
  "density_source",
  "pl_eqt",
  "temperature_proxy_k",
  "temperature_method",
  "escape_velocity_ratio",
  "esi_radius",
  "esi_density",
  "esi_escape",
  "esi_temperature",
  "esi",
  "high_esi",
  "esi_eligible",
  "esi_exclusion_reason"
)]

# Save the ESI results
write.csv(
  esi_results,
  "data/processed/esi_results.csv",
  row.names = FALSE
)

# Validate the ESI results
sum(esi_results$esi_eligible)
sum(esi_results$high_esi)
range(esi_results$esi, na.rm = TRUE)

# Display the ten highest ESI scores
head(
  esi_results[
    order(esi_results$esi, decreasing = TRUE),
    c("pl_name", "esi")
  ],
  10
)

earth_esi <- (
  similarity_score(1, 1, 0.57) *
    similarity_score(5.514, 5.514, 1.07) *
    similarity_score(1, 1, 0.70) *
    similarity_score(288, 288, 5.58)
) ^ (1 / 4)

earth_esi
