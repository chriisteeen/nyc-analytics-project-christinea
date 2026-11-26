# John Frasier SQ3

#Load in packages - dplyr for data cleaning and filtering, ggplot for visuals, 
#  & httr for Gaia connection
library(dplyr)
library(ggplot2)
library(httr)

# step 1 --------------------------------------------
#load in cleaned NASA table into df and counts number of records into total_planets
df <- read.csv("data/processed/nasa_clean.csv", stringsAsFactors = FALSE)
total_planets <- nrow(df)

# create a list for system distance (sy_dist) and starlight dip deepness during transit (pl_trandep)
obs_cols <- c("sy_dist", "pl_trandep")

#calculate % for any missing sy_dist and pl_trandep and round to 2 decimal places
missing_obs_pct <- (colSums(is.na(df[obs_cols])) / total_planets) * 100
round(missing_obs_pct, 2)

# calculate % for any missing gaia planet IDs and 
# % of existing gaia planet IDs to 2 decimal places
missing_gaia <- sum(is.na(df$gaia_dr3_id) | df$gaia_dr3_id == "")
pct_has_gaia <- ((total_planets - missing_gaia) / total_planets) * 100
cat("Planets with Gaia ID:", round(pct_has_gaia, 2), "%\n")

#step 2 -------------------------------------------------
# remove the "Gaia DR3" text so only the star ID remains
df$gaia_source_id <- gsub("^Gaia DR3 ", "", trimws(df$gaia_dr3_id))

# set up a filter for sy_dist <= 100, a non-zero or NA pl_trandep, a non-blank or NA sy_dist, with gaia IDs.. basic filtering for my SQ
candidate_planets <- df %>%
  filter(!is.na(sy_dist) & sy_dist <= 100 & 
           !is.na(pl_trandep) & pl_trandep > 0 & 
           !is.na(gaia_source_id) & gaia_source_id != "")

# based on prof feedback - week 4: count only distinct stars so multi-planet systems don't bias stats
unique_hosts <- candidate_planets %>%
  distinct(hostname, .keep_all = TRUE)

#print results on screen - how many candidate planets that match filters and how many unique host stars
cat("Candidate Planets:", nrow(candidate_planets), "\n")
cat("Unique Host Stars:", nrow(unique_hosts), "\n")

# step 3 -------------------------------------------------------
# set the file path for locally saving the Gaia CSV
gaia_file <- "data/raw/gaia_nearby_hosts.csv"

#checks if the gaia file already exists, just use existing file... otherwise, pull API query
if (!file.exists(gaia_file)) {
  # format host star IDs into CSL formatted for SQL
  clean_ids <- unique_hosts$gaia_source_id[grepl("^[0-9]+$", unique_hosts$gaia_source_id)]
  id_list <- paste0("'", clean_ids, "'", collapse = ",")
  
  #query the source_id, parallax (distance indicator), phot_g_mean_mag (optical brightness), and RUWE (wobble score) for unique host stars
  query_text <- paste0(
    "SELECT source_id, parallax, phot_g_mean_mag, ruwe ",
    "FROM gaiadr3.gaia_source WHERE source_id IN (", id_list, ")"
  )
  
  #send an http POST request to the ESA Gaia TAP server and give it 180 seconds 
  res <- POST(
    url = "https://gea.esac.esa.int/tap-server/tap/sync",
    body = list(REQUEST = "doQuery", LANG = "ADQL", FORMAT = "csv", QUERY = query_text),
    encode = "form",
    timeout(180)
  )
  
  #convert the text returned from POST request as a df and save it locally to data/raw
  gaia_data <- read.csv(text = content(res, as = "text"), colClasses = c("source_id" = "character"))
  write.csv(gaia_data, gaia_file, row.names = FALSE)
} else {
  gaia_data <- read.csv(gaia_file, colClasses = c("source_id" = "character"))
}

#step 4 ------------------------------------------------------
# Merge Gaia columns with host stars and classify by RUWE <= 1.4
hosts_clean <- unique_hosts %>%
  select(hostname, gaia_source_id, sy_dist, pl_trandep) %>%
  left_join(gaia_data, by = c("gaia_source_id" = "source_id")) %>%
  mutate(
    star_type = ifelse(ruwe <= 1.4, "Single Star (Clean)", "Disturbed / Binary Star")
  )
#print the counts
cat("Astrometric Star Breakdown:\n")
print(table(hosts_clean$star_type))

#step 5 -------------------------------------------------------
#drop rows missing brightness or star type before plotting
plot_data <- hosts_clean %>% filter(!is.na(phot_g_mean_mag) & !is.na(star_type))

#initialize the ggplot.. put brightness on y, sy_dist on x, color the dots based on star stability
fig3 <- ggplot(plot_data, aes(x = sy_dist, y = phot_g_mean_mag, color = star_type)) +
 
   # week 5 feedback: highlight the high-priority target box on the plot
  annotate("rect", xmin = 0, xmax = 35, ymin = 12, ymax = 4,
           fill = "forestgreen", alpha = 0.15, linetype = "dashed", color = "forestgreen") +
  annotate("text", x = 18, y = 5, label = "High-Priority Triage Window\n(d <= 35 pc, G <= 12 mag)",
           fontface = "bold", size = 3.5, color = "darkgreen") +
  
  #plot data points and assign colors
  geom_point(size = 2, alpha = 0.8) +
  scale_y_reverse() + # Brighter stars are smaller numbers in astronomy
  scale_color_manual(values = c("Single Star (Clean)" = "forestgreen", 
                                "Disturbed / Binary Star" = "firebrick")) +
  
  #add titles and labels
  labs(
    title = "Observational Feasibility: Host Distance vs. Optical Brightness",
    x = "Distance from Earth (Parsecs)",
    y = "Gaia G-band Magnitude (Brighter Stars Upward)",
    color = "Host Stability"
  ) +
  theme_minimal()

#print and save figure to figures folder
print(fig3)
ggsave("figures/gaia_observability_eda.png", fig3, width = 7, height = 4.5)



#step 6 ------------------------------------------------------
# categorize planets into 3 tiers: Tier 1 = prime candidates; Tier 2 = secondary; or Disqualified for Binary system instability
planets_tiered <- candidate_planets %>%
  left_join(select(hosts_clean, hostname, phot_g_mean_mag, ruwe, star_type), by = "hostname") %>%
  mutate(
    priority_tier = case_when(
      ruwe > 1.4 ~ "Disqualified (Binary Noise)",
      sy_dist <= 35 & phot_g_mean_mag <= 12.0 ~ "Tier 1: Prime Target (Nearby & Bright)",
      TRUE ~ "Tier 2: Secondary Target (Fainter / Farther)"
    )
  )

#print summary table showing how many planets fall into each tier
cat("\nPlanets per Priority Tier:\n")
print(table(planets_tiered$priority_tier))

# Top prime targets
tier1_shortlist <- planets_tiered %>%
  filter(priority_tier == "Tier 1: Prime Target (Nearby & Bright)") %>%
  select(pl_name, hostname, sy_dist, phot_g_mean_mag, ruwe, pl_trandep) %>%
  arrange(sy_dist)

head(tier1_shortlist, 5)

#step 7 ------------------------------------------------
# Resample 2,000 times for a 95% confidence interval for the binary star rate and calculate % of stars in sample with excess wobble
set.seed(2026)
boot_binary <- replicate(2000, {
  sample_ruwe <- sample(hosts_clean$ruwe[!is.na(hosts_clean$ruwe)], replace = TRUE)
  mean(sample_ruwe > 1.4) * 100
})

ci_95 <- quantile(boot_binary, probs = c(0.025, 0.975))

#print binary star contamination rate and lower / upper bounds
cat("\nObserved Binary Rate:", round(mean(hosts_clean$ruwe > 1.4, na.rm = TRUE) * 100, 2), "%\n")
cat("95% Bootstrap CI    : [", round(ci_95[1], 2), "%,", round(ci_95[2], 2), "% ]\n")