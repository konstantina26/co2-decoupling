# ==============================================================================
# Project: Which countries achieved absolute decoupling of GDP growth from
#          CO2 emissions between 2000 and 2022?
# Data:    Our World in Data - CO2 and Greenhouse Gas Emissions dataset
#          https://github.com/owid/co2-data
# Run:     from the project folder, with  Rscript Analysis.R
#          (or open the folder in VS Code and run the file line by line)
# ==============================================================================

library(tidyverse)

# ----------------------------- Parameters -------------------------------------
URL        <- "https://raw.githubusercontent.com/owid/co2-data/master/owid-co2-data.csv"
YEAR_START <- 2000
YEAR_END   <- 2022
OUTPUT_DIR <- "figures"   # created next to the script's working directory

dir.create(OUTPUT_DIR, showWarnings = FALSE)


# ----------------------------- 1. Load the data -------------------------------
co2_raw <- read_csv(URL, show_col_types = FALSE)

cat("Raw data:", nrow(co2_raw), "rows,", ncol(co2_raw), "columns\n")
cat("Years covered:", min(co2_raw$year), "-", max(co2_raw$year), "\n")


# ----------------------------- 2. Clean the data ------------------------------
# Keep real countries only: aggregates such as "World" or "Europe" have either
# no iso_code or an iso_code starting with "OWID_".
co2_clean <- co2_raw %>%
  filter(!is.na(iso_code),
         !str_starts(iso_code, "OWID_"),
         year %in% c(YEAR_START, YEAR_END)) %>%
  select(country, iso_code, year, gdp, co2)

# Keep only countries with GDP and CO2 data in BOTH years
co2_complete <- co2_clean %>%
  filter(!is.na(gdp), !is.na(co2)) %>%
  group_by(country) %>%
  filter(n() == 2) %>%
  ungroup()

cat("Countries with complete data:", n_distinct(co2_complete$country), "\n")


# ----------------------------- 3. Decoupling ----------------------------------
decoupling <- co2_complete %>%
  mutate(period = if_else(year == YEAR_START, "start", "end")) %>%
  select(country, iso_code, period, gdp, co2) %>%
  pivot_wider(names_from = period, values_from = c(gdp, co2)) %>%
  filter(co2_start > 0) %>%   # avoid dividing by zero
  mutate(
    gdp_change_pct = (gdp_end - gdp_start) / gdp_start * 100,
    co2_change_pct = (co2_end - co2_start) / co2_start * 100,
    category = case_when(
      gdp_change_pct > 0 & co2_change_pct < 0 ~ "Absolute decoupling",
      gdp_change_pct > 0 & co2_change_pct >= 0 &
        co2_change_pct < gdp_change_pct       ~ "Relative decoupling",
      TRUE                                    ~ "No decoupling"
    )
  )

cat("\nCountries per category:\n")
print(count(decoupling, category))

cat("\nCountries with absolute decoupling (sorted by CO2 change):\n")
decoupling %>%
  filter(category == "Absolute decoupling") %>%
  arrange(co2_change_pct) %>%
  select(country, gdp_change_pct, co2_change_pct) %>%
  print(n = Inf)


# ----------------------------- 4. Summary statistics --------------------------
n_total <- nrow(decoupling)

summary_table <- decoupling %>%
  group_by(category) %>%
  summarise(
    n = n(),
    share_pct = round(n() / n_total * 100, 1),
    median_gdp_change = round(median(gdp_change_pct), 1),
    median_co2_change = round(median(co2_change_pct), 1)
  )
cat("\nSummary table:\n")
print(summary_table)

# Uncertainty on the number of absolute decouplers (counting statistics)
n_abs <- sum(decoupling$category == "Absolute decoupling")
cat("\nAbsolute decoupling:", n_abs, "+/-", round(sqrt(n_abs), 1), "countries\n")

# Correlation between GDP growth and CO2 growth (Spearman rank correlation)
cor_result <- cor.test(decoupling$gdp_change_pct, decoupling$co2_change_pct,
                       method = "spearman", exact = FALSE)
cat("\nSpearman correlation:\n")
print(cor_result)


# ----------------------------- 5. Plot 1: scatter -----------------------------
p1 <- ggplot(decoupling,
             aes(x = gdp_change_pct, y = co2_change_pct, colour = category)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
  geom_point(alpha = 0.8, size = 2) +
  scale_colour_manual(values = c("Absolute decoupling" = "#1b9e77",
                                 "Relative decoupling" = "#7570b3",
                                 "No decoupling"       = "#d95f02")) +
  labs(title = paste0("GDP growth vs CO2 emissions growth, ",
                      YEAR_START, "-", YEAR_END),
       x = "GDP change (%)",
       y = "CO2 emissions change (%)",
       colour = "Category",
       caption = paste0("Source: Our World in Data (", n_total, " countries)")) +
  theme_minimal() +
  # zoom in: a few extreme countries lie outside this window
  coord_cartesian(xlim = c(-100, 600), ylim = c(-100, 600))

print(p1)
ggsave(file.path(OUTPUT_DIR, "decoupling_scatter.png"),
       p1, width = 8, height = 5, dpi = 300)


# ----------------------------- 6. Plot 2: top 10 -------------------------------
top10 <- decoupling %>%
  filter(category == "Absolute decoupling") %>%
  arrange(co2_change_pct) %>%
  slice_head(n = 10)

p2 <- ggplot(top10, aes(x = reorder(country, -co2_change_pct),
                        y = co2_change_pct)) +
  geom_col(fill = "#1b9e77") +
  geom_text(aes(label = paste0(round(co2_change_pct, 1), "%")),
            hjust = -0.1, colour = "white") +
  coord_flip() +
  labs(title = paste0("Top 10 countries by CO2 reduction while GDP grew, ",
                      YEAR_START, "-", YEAR_END),
       x = NULL,
       y = "CO2 emissions change (%)",
       caption = "Source: Our World in Data") +
  theme_minimal()

print(p2)
ggsave(file.path(OUTPUT_DIR, "top10_decoupling.png"),
       p2, width = 8, height = 5, dpi = 300)

cat("\nDone. Figures saved in '", OUTPUT_DIR, "/'\n", sep = "")