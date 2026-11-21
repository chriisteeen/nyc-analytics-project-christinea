# ==============================================================================
# STA 9750 - Group Integration Pipeline
# Team R&P | Synthesizing SQ1 (Albina) & SQ3 (John)
# ==============================================================================

suppressPackageStartupMessages(library(dplyr))

# ------------------------------------------------------------------------------
# 1. Load Processed Tables
# ------------------------------------------------------------------------------
find_path <- function(filename) {
  paths <- c(
    file.path("data/processed", filename),
    file.path("../../data/processed", filename),
    filename
  )
  paths[file.exists(paths)][1]
}

esi_path  <- find_path("esi_results.csv")
gaia_path <- find_path("gaia_hosts_clean.csv")

if (is.na(esi_path) || is.na(gaia_path)) {
  stop("Missing required input files in data/processed/. Ensure both scripts have run.")
}

esi_df  <- read.csv(esi_path, stringsAsFactors = FALSE)
gaia_df <- read.csv(gaia_path, stringsAsFactors = FALSE)

# ------------------------------------------------------------------------------
# 2. Key Harmonization & Relational Join (Using hostname)
# ------------------------------------------------------------------------------
# Trim hostnames to avoid whitespace mismatch
esi_df$hostname  <- trimws(esi_df$hostname)
gaia_df$hostname <- trimws(gaia_df$hostname)

# Select unique stellar host properties from Gaia
gaia_stellar <- gaia_df %>%
  select(hostname, sy_dist, phot_g_mean_mag, ruwe, astrometric_quality) %>%
  distinct(hostname, .keep_all = TRUE)

# Join planetary ESI metrics to host star observational parameters
integrated_pool <- inner_join(esi_df, gaia_stellar, by = "hostname")

cat("Total Candidate Planets in Observational Sample:", nrow(integrated_pool), "\n")

# ------------------------------------------------------------------------------
# 3. Apply Multi-SQ Screening Filters
# ------------------------------------------------------------------------------
# A. Flag candidates disqualified by astrometric noise / binary disturbance
flagged_binaries <- integrated_pool %>%
  filter(high_esi == TRUE, ruwe > 1.4)

cat("\n--- Astrometrically Contaminated Candidates (Excluded: RUWE > 1.4) ---\n")
print(flagged_binaries %>% select(pl_name, hostname, esi, ruwe, sy_dist, phot_g_mean_mag))

# B. Isolate clean high-ESI candidates orbiting single stars (RUWE <= 1.4)
clean_high_esi <- integrated_pool %>%
  filter(high_esi == TRUE, ruwe <= 1.4)

cat("\n--- High-ESI Worlds Orbiting Clean Single Stars (n =", nrow(clean_high_esi), ") ---\n")

# ------------------------------------------------------------------------------
# 4. Rank High-Priority Triage Targets (Inside Priority Box: d <= 35 pc, G <= 12.0)
# ------------------------------------------------------------------------------
triage_targets <- clean_high_esi %>%
  filter(sy_dist <= 35, phot_g_mean_mag <= 12.0) %>%
  select(pl_name, hostname, esi, pl_rade, pl_bmasse, pl_eqt, sy_dist, phot_g_mean_mag, ruwe) %>%
  arrange(sy_dist)

cat("\n--- Top Triage Shortlist for Immediate Follow-Up Spectroscopy ---\n")
print(triage_targets)

# Export the finalized table
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
write.csv(clean_high_esi, "data/processed/integrated_high_esi_targets.csv", row.names = FALSE)
cat("\nSaved integrated findings to: data/processed/integrated_high_esi_targets.csv\n")