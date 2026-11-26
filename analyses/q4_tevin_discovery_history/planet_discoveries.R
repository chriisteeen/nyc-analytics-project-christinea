install.packages("tidyverse")
library("tidyverse")

#Read data. Update when joined to group data
nasa <- read.csv("data/processed/nasa_clean.csv")
esi <- read.csv("data/processed/esi_results.csv")
tech <- read.csv("data/processed/tech_discovery.csv")

#Join nasa and esi df's
class(nasa)

colnames(esi)
colnames(nasa)
esi_only <- esi %>% select(pl_name, density_source, temperature_proxy_k, 
                              temperature_method, escape_velocity_ratio, 
                              esi_radius, esi_density, esi_escape, 
                              esi_temperature, esi, high_esi, esi_eligible, 
                              esi_exclusion_reason)
nasa_esi <- inner_join(nasa, esi_only, by = "pl_name", relationship = "one-to-one")

head(nasa_esi, 1)
colnames(nasa_esi)

#Trim joined df to pertinent columns 
nasa_esi <- nasa_esi %>% select(pl_name, hostname, 
                                gaia_dr3_id, disc_year, 
                                discoverymethod, disc_facility, disc_telescope, 
                                disc_instrument, esi, esi_ready, high_esi, 
                                esi_eligible, esi_exclusion_reason)
head(nasa_esi)


#Graph raw planet discoveries per year
disc_by_year <- nasa_esi %>% count(disc_year, name = "planets")
disc_year_chart <- ggplot(disc_by_year, aes(x=disc_year, y=planets))+geom_col(fill = "steelblue")+
  labs(title="Exoplants Discovered per Year", x="Discovery Year",
       y="Number of Planets")+scale_x_continuous(breaks=seq(1992, 2026, by=2))
disc_year_chart
decade_count <- nasa_esi %>% filter(between(disc_year, 2010, 2019)) %>% nrow()
decade_count
ggsave("analyses/q4_tevin_discovery_history/planet_discovery_year.png", plot = disc_year_chart, width=8, height=6, units="in", dpi=300)

#Show tech discovery years on graph
head(tech,12)
disc_year_tech_chart <- ggplot(disc_by_year, aes(x=disc_year, y=planets))+geom_col(fill = "steelblue")+
  labs(title="Exoplants Discovered per Year", x="Discovery Year",
       y="Number of Planets")+scale_x_continuous(breaks=seq(1992, 2026, by=2))+
  geom_vline(data=tech %>% filter(tech_year>=1992), aes(xintercept=tech_year),
             linetype="dashed", color="darkred")+geom_text(data=tech %>% 
              filter(tech_year>=1992), aes(x=tech_year, y=Inf, label=tech_name),
              angle=90, hjust=2.5, vjust=-.4, size=3)
disc_year_tech_chart
ggsave("analyses/q4_tevin_discovery_history/planet_discovery_tech_year.png", plot = disc_year_tech_chart, width=8, height=6, units="in", dpi=300)

#Create a similar graph but just for planets with high esi
high_esi <- nasa_esi %>% filter(high_esi == TRUE)

tech_labels <- tech %>%
  filter(tech_year >= 1992) %>%
  group_by(tech_year) %>%
  mutate(label_vjust = if_else(row_number() == 1, -0.4, 1.4)) %>%
  ungroup()

high_by_year <- high_esi %>% count(disc_year, name="planets")
high_esi_plans <- ggplot(high_by_year, aes(x=disc_year, y=planets))+
  geom_col(fill="darkorange")+geom_vline(data=tech_labels, 
  aes(xintercept=tech_year), linetype="dashed",color="darkred")+
  scale_x_continuous(breaks=seq(1992, 2026, by=2))+
  coord_cartesian(xlim=c(1992,2026))+labs(x="Discovery Year", y="High ESI Planets")+
  geom_text(data=tech %>%filter(tech_year>=1992), aes(x=tech_year, y=Inf, 
  label=tech_name), angle=90, hjust=2.5, vjust=-.4, size=3)
high_esi_plans

decade_esi <- high_esi %>% filter(between(disc_year, 2010, 2019)) %>% nrow()
ggsave("analyses/q4_tevin_discovery_history/high_esi_planets.png", plot = high_esi_plans, width=8, height=6, units="in", dpi=300)

#Calculate the facilities that have discovered high esi planets
high_esi_fac <- high_esi %>%
  count(disc_facility, name = "high_esi_planets", sort = TRUE)
high_esi_fac

#Graph distribution of facilities discovery of high esi planets
high_esi_fac_plot <- ggplot(high_esi_fac,
       aes(x = high_esi_planets, y = reorder(disc_facility, high_esi_planets))) +
  geom_col(fill = "darkgoldenrod2") +
  geom_text(aes(label = high_esi_planets), hjust = -0.3, size = 3) +
  labs(title = "High ESI Planets by Discovery Facility",
       x = "Number of High ESI Planets", y = NULL)
high_esi_fac_plot
ggsave("analyses/q4_tevin_discovery_history/high_esi_facility_discovery.png", plot = high_esi_fac_plot, width=8, height=6, units="in", dpi=300)
