library(dplyr)
library(ggplot2)

# ------------------------------------------------------------------------------
# 1. Data Ingestion & Quality Assessment
# ------------------------------------------------------------------------------

# 1. Ingest dataset skipping metadata comments starting with '#'
df <- read.csv("analyses/q1_christine_host_stars/PSCompPars_2026.10.10_11.49.34.csv", comment.char = "#")

# 2. Select required analytical features and remove incomplete rows
exo_data <- df %>% 
  select(pl_name, hostname, discoverymethod, st_teff, st_mass, st_rad, pl_insol, pl_orbsmax, pl_rade) %>% 
  na.omit()

# 3. Restrict analysis to strictly positive physical values
exo_clean <- exo_data %>% 
  filter(st_teff > 0 & st_rad > 0 & st_mass > 0 & pl_insol > 0 & pl_orbsmax > 0)

cat("Cleaned dataset record count:", nrow(exo_clean), "\n")


# ------------------------------------------------------------------------------
# 2. Physical Framework & Temperature-Adjusted Habitable Zone
# ------------------------------------------------------------------------------

# Temperature-dependent boundary flux limit functions
calc_seff_inner <- function(teff) {
  t_star <- teff - 5780
  return(1.0146 + (1.2456e-4 * t_star) + (1.4612e-8 * t_star^2) - (7.6345e-12 * t_star^3) - (1.7511e-15 * t_star^4))
}

calc_seff_outer <- function(teff) {
  t_star <- teff - 5780
  return(0.3560 + (5.9578e-5 * t_star) + (1.6707e-9 * t_star^2) - (3.0058e-12 * t_star^3) - (5.1925e-16 * t_star^4))
}

# Apply temperature-adjusted HZ flags and compare with fixed limit (0.25 <= pl_insol <= 1.1)
exo_clean <- exo_clean %>%
  mutate(
    seff_inner = calc_seff_inner(st_teff),
    seff_outer = calc_seff_outer(st_teff),
    in_dynamic_hz = (pl_insol <= seff_inner) & (pl_insol >= seff_outer),
    in_static_hz  = (pl_insol >= 0.25) & (pl_insol <= 1.1)
  )

# Compute transit probability and inverse weighting factor (1 AU = 215.032 Solar Radii)
exo_clean <- exo_clean %>%
  mutate(
    p_transit = (st_rad / (pl_orbsmax * 215.032)),
    p_transit = pmin(p_transit, 1.0), # Cap probability at 1.0
    weight_inv_p = 1 / p_transit
  )


# ------------------------------------------------------------------------------
# 3. Exploratory Data Analysis & Visualizations
# ------------------------------------------------------------------------------

# Transform columns for log plotting
exo_clean <- exo_clean %>%
  mutate(
    log_teff = log10(st_teff),
    log_insol = log10(pl_insol)
  )

# Figure 1: Temperature vs. Insolation colored by Stellar Radius
p1 <- ggplot(exo_clean, aes(x = st_teff, y = pl_insol, color = st_rad)) +
  geom_point(alpha = 0.5) +
  scale_x_log10() +
  scale_y_log10() +
  scale_color_viridis_c(trans = "log10", name = "Stellar Radius (R_sun)") +
  labs(
    title = "Stellar Effective Temperature vs. Planetary Insolation",
    x = "Stellar Effective Temperature (K, Log Scale)",
    y = "Planetary Insolation Flux (Earth Flux = 1, Log Scale)"
  ) +
  theme_minimal()

print(p1)

# Subset to Transit and Radial Velocity
method_data <- exo_clean %>%
  filter(discoverymethod %in% c("Transit", "Radial Velocity"))

# Figure 2: Temperature vs. Insolation by Discovery Method
p2 <- ggplot(method_data, aes(x = st_teff, y = pl_insol, color = discoverymethod)) +
  geom_point(alpha = 0.4) +
  scale_x_log10() +
  scale_y_log10() +
  scale_color_manual(values = c("Transit" = "purple", "Radial Velocity" = "green")) +
  labs(
    title = "Stellar Temperature vs. Insolation by Discovery Method",
    x = "Stellar Effective Temperature (K, Log Scale)",
    y = "Planetary Insolation Flux (Earth Flux = 1, Log Scale)",
    color = "Discovery Method"
  ) +
  theme_minimal()

print(p2)


# ------------------------------------------------------------------------------
# 4. Statistical Evaluation & Results
# ------------------------------------------------------------------------------

# 1. Summary table of raw yields
hz_summary <- method_data %>%
  group_by(discoverymethod) %>%
  summarise(
    Total_Planets = n(),
    Dynamic_HZ_Count = sum(in_dynamic_hz),
    Raw_Yield_Pct = (Dynamic_HZ_Count / Total_Planets) * 100
  )

print(hz_summary)

# 2. Chi-Square Test of Independence
contingency_matrix <- table(method_data$discoverymethod, method_data$in_dynamic_hz)
chisq_result <- chisq.test(contingency_matrix)
print(chisq_result)

