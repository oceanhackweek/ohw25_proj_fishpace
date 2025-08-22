# 2D Profile Plot: CTD Casts/Bottle Data with CEFI COBALT Chlorophyll Model
# Showcases observational vs model chlorophyll data in depth profiles

library(dplyr)
library(readr)
library(ggplot2)
library(viridis)
library(patchwork)
library(tidyr)

cat("=== 2D CTD-CEFI Chlorophyll Profile Analysis ===\n")

# Load datasets
cat("Loading datasets...\n")
cefi_data <- read_csv("cefi_cobalt_chlorophyll_3d.csv")

# Check for CTD bottle data and cast data for coordinates
ctd_file <- "calcofi_bottles_recent.csv"
cast_file <- "calcofi_194903-202105_cast.csv"

if (!file.exists(ctd_file)) {
  # Try historical data
  ctd_file <- "calcofi_194903-202105_bottle.csv"
}

if (file.exists(ctd_file) && file.exists(cast_file)) {
  ctd_data <- read_csv(ctd_file)
  cast_data <- read_csv(cast_file)
  cat("✓ Loaded CTD bottle data:", nrow(ctd_data), "records\n")
  cat("✓ Loaded CTD cast data:", nrow(cast_data), "records\n")
} else {
  stop("No CTD bottle and cast data found. Please run data download scripts first.")
}

cat("✓ Loaded CEFI data:", nrow(cefi_data), "records\n")

# Process CTD bottle data by joining with cast data for coordinates
ctd_processed <- ctd_data %>%
  # Filter for valid chlorophyll and depth data (use ChlorA column)
  filter(!is.na(ChlorA), !is.na(Depthm)) %>%
  # Join with cast data to get coordinates
  left_join(cast_data %>% select(Cst_Cnt, Lat_Dec, Lon_Dec, Year), by = "Cst_Cnt") %>%
  # Filter for records with coordinates
  filter(!is.na(Lat_Dec), !is.na(Lon_Dec)) %>%
  # Convert units: ug/L to mg/m³ (1 ug/L = 1 mg/m³)
  mutate(
    chlorophyll_mg_m3 = ChlorA,
    depth_m = Depthm,
    longitude = -abs(Lon_Dec),  # Ensure negative longitude for West coast
    latitude = Lat_Dec,
    data_source = "CTD Observation"
  ) %>%
  # Filter to reasonable depth range and California Current region
  filter(
    depth_m >= 0, depth_m <= 200,
    longitude >= -130, longitude <= -115,
    latitude >= 28, latitude <= 42,
    chlorophyll_mg_m3 > 0, chlorophyll_mg_m3 < 50  # Remove extreme outliers
  ) %>%
  select(longitude, latitude, depth_m, chlorophyll_mg_m3, data_source, Year)

# Process CEFI model data
cefi_processed <- cefi_data %>%
  filter(!is.na(chlorophyll_mg_m3), depth_m <= 200) %>%
  mutate(data_source = "CEFI COBALT Model") %>%
  select(longitude, latitude, depth_m, chlorophyll_mg_m3, data_source, time)

cat("✓ Processed CTD data:", nrow(ctd_processed), "valid records\n")
cat("✓ Processed CEFI data:", nrow(cefi_processed), "valid records\n")

# Create depth bins for profile analysis
depth_bins <- seq(0, 200, by = 10)

# Bin CTD data by depth
ctd_binned <- ctd_processed %>%
  mutate(depth_bin = cut(depth_m, breaks = depth_bins, labels = FALSE)) %>%
  filter(!is.na(depth_bin)) %>%
  group_by(depth_bin) %>%
  summarise(
    depth_center = unique(depth_bins[depth_bin])[1] + 5,  # Use bin start + 5m for center
    mean_chl = mean(chlorophyll_mg_m3, na.rm = TRUE),
    median_chl = median(chlorophyll_mg_m3, na.rm = TRUE),
    sd_chl = sd(chlorophyll_mg_m3, na.rm = TRUE),
    n_obs = n(),
    data_source = "CTD Observation",
    .groups = "drop"
  ) %>%
  filter(n_obs >= 5)  # Require at least 5 observations per bin

# Bin CEFI data by depth
cefi_binned <- cefi_processed %>%
  mutate(depth_bin = cut(depth_m, breaks = depth_bins, labels = FALSE)) %>%
  filter(!is.na(depth_bin)) %>%
  group_by(depth_bin) %>%
  summarise(
    depth_center = unique(depth_bins[depth_bin])[1] + 5,  # Use bin start + 5m for center
    mean_chl = mean(chlorophyll_mg_m3, na.rm = TRUE),
    median_chl = median(chlorophyll_mg_m3, na.rm = TRUE),
    sd_chl = sd(chlorophyll_mg_m3, na.rm = TRUE),
    n_obs = n(),
    data_source = "CEFI COBALT Model",
    .groups = "drop"
  )

# Combine binned data
profile_data <- bind_rows(ctd_binned, cefi_binned)

cat("✓ Created depth-binned profiles\n")

# 1. Mean Chlorophyll Depth Profile
profile_plot <- ggplot(profile_data, aes(x = mean_chl, y = depth_center, color = data_source)) +
  geom_line(linewidth = 1.2, alpha = 0.8) +
  geom_point(size = 2.5, alpha = 0.9) +
  geom_ribbon(aes(xmin = mean_chl - sd_chl, xmax = mean_chl + sd_chl, fill = data_source), 
              alpha = 0.2, color = NA) +
  scale_color_manual(values = c("CTD Observation" = "#2E8B57", "CEFI COBALT Model" = "#FF6347")) +
  scale_fill_manual(values = c("CTD Observation" = "#2E8B57", "CEFI COBALT Model" = "#FF6347")) +
  scale_y_continuous(trans = "reverse", breaks = seq(0, 200, 25)) +  # Explicit reverse transformation with breaks
  labs(
    title = "Chlorophyll-a Depth Profiles: CTD Observations vs CEFI COBALT Model",
    subtitle = "California Current System (Surface at top, deeper values below)",
    x = "Chlorophyll-a (mg/m³)",
    y = "Depth (m) - Surface to Deep",
    color = "Data Source",
    fill = "Data Source"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )

# Save only the profile plot
ggsave("2d_ctd_cefi_chlorophyll_profiles.png", profile_plot, 
       width = 10, height = 8, dpi = 300, bg = "white")

cat("✓ Saved: 2d_ctd_cefi_chlorophyll_profiles.png\n")


# Generate summary statistics
cat("\n--- 2D Profile Analysis Summary ---\n")

# Overall statistics
ctd_summary <- ctd_processed %>%
  summarise(
    n_records = n(),
    depth_range = paste(round(min(depth_m), 1), "-", round(max(depth_m), 1), "m"),
    chl_range = paste(round(min(chlorophyll_mg_m3), 3), "-", round(max(chlorophyll_mg_m3), 3), "mg/m³"),
    mean_chl = round(mean(chlorophyll_mg_m3), 3),
    median_chl = round(median(chlorophyll_mg_m3), 3)
  )

cefi_summary <- cefi_processed %>%
  summarise(
    n_records = n(),
    depth_range = paste(round(min(depth_m), 1), "-", round(max(depth_m), 1), "m"),
    chl_range = paste(round(min(chlorophyll_mg_m3), 3), "-", round(max(chlorophyll_mg_m3), 3), "mg/m³"),
    mean_chl = round(mean(chlorophyll_mg_m3), 3),
    median_chl = round(median(chlorophyll_mg_m3), 3)
  )

cat("CTD Observations:\n")
cat("  Records:", ctd_summary$n_records, "\n")
cat("  Depth range:", ctd_summary$depth_range, "\n")
cat("  Chlorophyll range:", ctd_summary$chl_range, "\n")
cat("  Mean chlorophyll:", ctd_summary$mean_chl, "mg/m³\n")
cat("  Median chlorophyll:", ctd_summary$median_chl, "mg/m³\n")

cat("\nCEFI COBALT Model:\n")
cat("  Records:", cefi_summary$n_records, "\n")
cat("  Depth range:", cefi_summary$depth_range, "\n")
cat("  Chlorophyll range:", cefi_summary$chl_range, "\n")
cat("  Mean chlorophyll:", cefi_summary$mean_chl, "mg/m³\n")
cat("  Median chlorophyll:", cefi_summary$median_chl, "mg/m³\n")

if (exists("correlation")) {
  cat("\nModel-Observation Correlation:", round(correlation, 3), "\n")
}

cat("\n📊 2D CTD-CEFI Profile Analysis Complete!\n")
cat("Generated depth profile comparison showing chlorophyll vs depth.\n")
cat("File saved as: 2d_ctd_cefi_chlorophyll_profiles.png\n")
