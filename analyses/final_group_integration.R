# Final group integration: Team R&P

library(dplyr)
library(ggplot2)

# Import existing results
nasa <- read.csv("data/processed/nasa_clean.csv")
esi <- read.csv("data/processed/esi_results.csv")
composition <- read.csv("data/processed/albina_composition_results.csv")
observability <- read.csv("data/processed/planets_tiered_observability.csv")

# Confirm each table contains one row per planet
stopifnot(
  !anyDuplicated(nasa$pl_name),
  !anyDuplicated(esi$pl_name),
  !anyDuplicated(composition$pl_name),
  !anyDuplicated(observability$pl_name)
)

# Combine results using planet names
group_results <- esi %>%
  left_join(
    composition %>%
      select(pl_name, composition, interior_esi),
    by = "pl_name"
  ) %>%
  left_join(
    nasa %>%
      select(
        pl_name, sy_dist, disc_year,
        discoverymethod, disc_facility
      ),
    by = "pl_name"
  ) %>%
  left_join(
    observability %>%
      select(
        pl_name, phot_g_mean_mag, ruwe,
        pl_trandep, observational_tier
      ),
    by = "pl_name"
  )

# Confirm the joins preserved the original number of planets
stopifnot(nrow(group_results) == nrow(esi))

# Add habitable-zone assessment

christine <- read.csv(
  "analyses/q1_christine_host_stars/PSCompPars_2026.10.10_11.49.34.csv",
  comment.char = "#"
)

# Match analytical sample
hz_results <- christine %>%
  select(
    pl_name, hostname, discoverymethod,
    st_teff, st_mass, st_rad,
    pl_insol, pl_orbsmax, pl_rade
  ) %>%
  na.omit() %>%
  filter(
    st_teff > 0,
    st_mass > 0,
    st_rad > 0,
    pl_insol > 0,
    pl_orbsmax > 0
  ) %>%
  mutate(
    # Temperature difference from the Sun
    t_star = st_teff - 5780,
    
    # Christine's inner and outer HZ boundaries
    seff_inner = 1.0146 +
      1.2456e-4 * t_star +
      1.4612e-8 * t_star^2 -
      7.6345e-12 * t_star^3 -
      1.7511e-15 * t_star^4,
    
    seff_outer = 0.3560 +
      5.9578e-5 * t_star +
      1.6707e-9 * t_star^2 -
      3.0058e-12 * t_star^3 -
      5.1925e-16 * t_star^4,
    
    hz_status = case_when(
      st_teff < 2600 | st_teff > 7200 ~
        "Not assessed: temperature outside model range",
      
      pl_insol >= seff_outer & pl_insol <= seff_inner ~
        "Inside modeled HZ",
      
      TRUE ~ "Outside modeled HZ"
    )
  ) %>%
  select(
    pl_name, st_teff, pl_insol,
    seff_inner, seff_outer, hz_status
  )

# Confirm one assessment per planet
stopifnot(!anyDuplicated(hz_results$pl_name))

# Join to the combined results
group_results <- group_results %>%
  left_join(hz_results, by = "pl_name") %>%
  mutate(
    hz_status = coalesce(
      hz_status,
      "Not assessed: absent from Christine's cleaned sample"
    )
  )

# Check the combined table
stopifnot(nrow(group_results) == nrow(esi))

table(group_results$hz_status)
dim(group_results)

# Compare high-ESI, rocky-like candidates
candidate_comparison <- group_results %>%
  filter(
    high_esi,
    composition == "Rocky-like"
  ) %>%
  select(
    pl_name, esi, interior_esi,
    hz_status, sy_dist,
    observational_tier,
    disc_year, disc_facility
  ) %>%
  arrange(desc(esi))

View(candidate_comparison)

# Save the combined results for all planets
write.csv(
  group_results,
  "data/processed/final_group_results.csv",
  row.names = FALSE
)

# Save the 17 high-ESI, rocky-like candidates
write.csv(
  candidate_comparison,
  "data/processed/final_candidate_comparison.csv",
  row.names = FALSE
)

# Habitable-zone results among the 17 candidates
table(candidate_comparison$hz_status)

# Observability results, including planets not assessed
table(candidate_comparison$observational_tier, useNA = "ifany")

candidate_comparison %>%
  filter(hz_status == "Inside modeled HZ") %>%
  select(pl_name, esi, interior_esi, sy_dist)

candidate_comparison %>%
  filter(grepl("^Tier 1:", observational_tier)) %>%
  select(pl_name, esi, interior_esi, hz_status, sy_dist)

final_plot <- ggplot(
  candidate_comparison,
  aes(
    x = esi,
    y = reorder(pl_name, esi),
    fill = hz_status == "Inside modeled HZ"
  )
) +
  geom_col(width = 0.65) +
  scale_fill_manual(
    values = c("FALSE" = "grey75", "TRUE" = "#253858"),
    guide = "none"
  ) +
  scale_x_continuous(limits = c(0, 1)) +
  labs(
    title = "Comparing 17 high-ESI, rocky-like candidates",
    subtitle = "Selected for high adapted ESI and rocky-like classification",
    x = "Adapted Earth Similarity Index",
    y = NULL,
    caption = paste(
      "Navy: inside the modeled habitable zone.",
      "Gray: outside or not assessed.\n",
      "Earth similarity does not establish habitability."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 17),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(hjust = 0),
    axis.text.y = element_text(color = "black")
  )

final_plot

distance_plot <- ggplot(
  candidate_comparison,
  aes(x = sy_dist, y = esi)
) +
  geom_point(
    color = "grey65",
    size = 3
  ) +
  geom_point(
    data = subset(
      candidate_comparison,
      hz_status == "Inside modeled HZ"
    ),
    color = "#253858",
    size = 3.5
  ) +
  geom_text(
    data = subset(
      candidate_comparison,
      hz_status == "Inside modeled HZ" |
        pl_name == "Gliese 12 b"
    ),
    aes(label = pl_name),
    nudge_x = 1.5,
    hjust = 0,
    size = 3.3,
    check_overlap = TRUE
  ) +
  labs(
    title = "Nearby candidates offer different strengths",
    x = "Distance from Earth (parsecs)",
    y = "Adapted Earth Similarity Index",
    caption = paste(
      "Navy: inside the modeled habitable zone.",
      "Gray: outside or not assessed.\n",
      "Distance alone does not determine observability."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(hjust = 0)
  )

distance_plot

ggsave(
  "final_candidate_ranking.png",
  plot = final_plot,
  width = 10, height = 7,
  dpi = 300, bg = "white"
)

ggsave(
  "final_candidate_distance.png",
  plot = distance_plot,
  width = 10, height = 6,
  dpi = 300, bg = "white"
)

# Discovery history of the 17 candidates
candidate_comparison %>%
  select(pl_name, disc_year, disc_facility, esi) %>%
  arrange(disc_year)

