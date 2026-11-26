# Albina Q2: Earth-like radius, mass, and rocky composition

# CONDITIONS:
# Radius: 0.5 < pl_rade <= 1.5 Earth radii
# Mass: 0.1 < pl_bmasse <= 3 Earth masses
# A planet must satisfy both conditions.

library(ggplot2)

# Import the shared ESI results
esi_results <- read.csv("data/processed/esi_results.csv")

# Select planets within Earth-like radius and mass boundaries
earth_candidates <- esi_results[
  !is.na(esi_results$pl_rade) &
    !is.na(esi_results$pl_bmasse) &
    esi_results$pl_rade > 0.5 &
    esi_results$pl_rade <= 1.5 &
    esi_results$pl_bmasse > 0.1 &
    esi_results$pl_bmasse <= 3,
]

# Count the qualifying planets
nrow(earth_candidates)

# Calculate Interior ESI using radius and density

earth_candidates$radius_score <- (
  1 - abs(
    (earth_candidates$pl_rade - 1) /
      (earth_candidates$pl_rade + 1)
  )
)^0.57

earth_candidates$density_score <- (
  1 - abs(
    (earth_candidates$pl_dens - 5.514) /
      (earth_candidates$pl_dens + 5.514)
  )
)^1.07

earth_candidates$interior_esi <- sqrt(
  earth_candidates$radius_score *
    earth_candidates$density_score
)

# Number with enough information for Interior ESI
sum(!is.na(earth_candidates$interior_esi))

# Check how planet masses were obtained
table(
  earth_candidates$pl_bmassprov,
  useNA = "ifany"
)

# Exclude masses estimated from a mass-radius relationship
empirical_candidates <- earth_candidates[
  !is.na(earth_candidates$pl_bmassprov) &
    earth_candidates$pl_bmassprov != "M-R relationship",
]

# Confirm sample size and mass provenance
nrow(empirical_candidates)

table(empirical_candidates$pl_bmassprov)

# Calculate expected mass from both empirical relationships
empirical_candidates$rocky_expected_mass <-
  0.90 * empirical_candidates$pl_rade^3.45

empirical_candidates$volatile_expected_mass <-
  1.74 * empirical_candidates$pl_rade^1.58

# Measure which relationship each planet is closer to
empirical_candidates$rocky_difference <- abs(
  log(
    empirical_candidates$pl_bmasse /
      empirical_candidates$rocky_expected_mass
  )
)

empirical_candidates$volatile_difference <- abs(
  log(
    empirical_candidates$pl_bmasse /
      empirical_candidates$volatile_expected_mass
  )
)

# Assign the closer empirical composition
empirical_candidates$composition <- ifelse(
  empirical_candidates$rocky_difference <=
    empirical_candidates$volatile_difference,
  "Rocky-like",
  "Volatile-rich-like"
)

# Show counts
composition_counts <- table(
  empirical_candidates$composition
)

composition_counts

# Show percentages
round(
  prop.table(composition_counts) * 100,
  1
)

# Prepare classification results for plotting
composition_summary <- data.frame(
  composition = names(composition_counts),
  count = as.numeric(composition_counts)
)

composition_summary$percent <- round(
  composition_summary$count /
    sum(composition_summary$count) * 100,
  1
)

# Create composition chart
composition_plot <- ggplot(
  composition_summary,
  aes(
    x = composition,
    y = percent,
    fill = composition
  )
) +
  geom_col(width = 0.6) +
  geom_text(
    aes(
      label = paste0(
        count,
        " planets\n",
        percent,
        "%"
      )
    ),
    vjust = -0.4,
    size = 4
  ) +
  scale_fill_manual(
    values = c(
      "Rocky-like" = "steelblue",
      "Volatile-rich-like" = "mediumpurple4"
    )
  ) +
  labs(
    title = "Estimated Composition of Earth-Like Candidates",
    subtitle = "146 candidates with non-M-R-derived masses",
    x = NULL,
    y = "Percentage of candidates"
  ) +
  ylim(0, 80) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold")
  )

composition_plot

ggsave(
  filename = "analyses/q2_albina_rocky_planets/composition_breakdown.png",
  plot = composition_plot,
  width = 7,
  height = 5,
  dpi = 300
)

write.csv(
  empirical_candidates[
    c(
      "pl_name",
      "composition",
      "interior_esi",
      "pl_rade",
      "pl_bmasse",
      "pl_dens",
      "pl_bmassprov"
    )
  ],
  "data/processed/albina_composition_results.csv",
  row.names = FALSE
)

rocky_ranked <- empirical_candidates[
  empirical_candidates$composition == "Rocky-like" &
    !is.na(empirical_candidates$interior_esi),
]

rocky_ranked <- rocky_ranked[
  order(rocky_ranked$interior_esi, decreasing = TRUE),
  c(
    "pl_name",
    "pl_rade",
    "pl_bmasse",
    "pl_dens",
    "pl_bmassprov",
    "interior_esi",
    "composition"
  )
]

head(rocky_ranked, 10)

write.csv(
  rocky_ranked,
  "analyses/q2_albina_rocky_planets/rocky_candidates_ranked.csv",
  row.names = FALSE
)

# Select the ten highest-ranked rocky-like planets
top_10_rocky <- head(rocky_ranked, 10)

# Arrange planet names from highest to lowest
top_10_rocky$pl_name <- factor(
  top_10_rocky$pl_name,
  levels = rev(top_10_rocky$pl_name)
)

# Create the plot
top_10_plot <- ggplot(
  top_10_rocky,
  aes(x = interior_esi, y = pl_name)
) +
  geom_point(
    color = "steelblue",
    size = 4
  ) +
  geom_text(
    aes(label = sprintf("%.3f", interior_esi)),
    nudge_x = 0.0005,
    hjust = 0,
    size = 3.5
  ) +
  scale_x_continuous(
    limits = c(0.987, 1.001),
    breaks = seq(0.988, 1.000, 0.002)
  ) +
  labs(
    title = "Highest Interior ESI Rocky-Like Candidates",
    subtitle =  "Top 10 of rocky-like planets with density data",
    caption = "Interior ESI uses radius and density only.\nValues closer to 1 indicate greater Earth similarity.",
    x = "Interior Earth Similarity Index",
    y = NULL
  ) +
  theme_minimal(base_size = 12)

top_10_plot

ggsave(
  "analyses/q2_albina_rocky_planets/top_10_rocky_candidates.png",
  plot = top_10_plot,
  width = 8,
  height = 5,
  dpi = 300
)



