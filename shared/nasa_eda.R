# Plot the distribution of adapted ESI scores

library(ggplot2)

esi_results <- read.csv(
  "data/processed/esi_results.csv"
)

esi_plot_data <- esi_results[
  !is.na(esi_results$esi),
]

high_esi_count <- sum(
  esi_plot_data$esi >= 0.80
)

esi_plot <- ggplot(
  esi_plot_data,
  aes(x = esi)
) +
  geom_histogram(
    binwidth = 0.025,
    fill = "gray50",
    color = "white"
  ) +
  geom_vline(
    xintercept = 0.80,
    color = "red",
    linewidth = 1
  ) +
  labs(
    title = "Distribution of Adapted ESI Scores",
    subtitle = paste(
      high_esi_count,
      "planets have an adapted ESI of 0.80 or higher"
    ),
    x = "Adapted Earth Similarity Index",
    y = "Number of Confirmed Exoplanets"
  ) +
  theme_minimal()

esi_plot

ggsave(
  "shared/esi/esi_distribution.png",
  plot = esi_plot,
  width = 8,
  height = 5,
  dpi = 300
)

