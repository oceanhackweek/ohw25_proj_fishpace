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
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  ) +
  coord_cartesian(xlim = c(0, max(profile_data$mean_chl + profile_data$sd_chl, na.rm = TRUE) * 1.1))

# 2. Scatter plot comparison at different depths
scatter_data <- profile_data %>%
  select(depth_center, mean_chl, data_source) %>%
  pivot_wider(names_from = data_source, values_from = mean_chl) %>%
  filter(!is.na(`CTD Observation`), !is.na(`CEFI COBALT Model`))

if (nrow(scatter_data) > 0) {
  scatter_plot <- ggplot(scatter_data, aes(x = `CTD Observation`, y = `CEFI COBALT Model`)) +
    geom_point(aes(color = depth_center), size = 3, alpha = 0.8) +
    geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "dashed") +
    geom_abline(slope = 1, intercept = 0, color = "red", linetype = "solid", alpha = 0.7) +
    scale_color_viridis_c(name = "Depth (m)", trans = "reverse") +
    labs(
      title = "CTD vs CEFI COBALT Chlorophyll Comparison",
      subtitle = "1:1 line (red) vs fitted relationship (dashed)",
      x = "CTD Observed Chlorophyll-a (mg/m³)",
      y = "CEFI COBALT Model Chlorophyll-a (mg/m³)"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12)
    )
  
  # Calculate correlation
  correlation <- cor(scatter_data$`CTD Observation`, scatter_data$`CEFI COBALT Model`, use = "complete.obs")
  cat("Correlation between CTD and CEFI chlorophyll:", round(correlation, 3), "\n")
} else {
  scatter_plot <- ggplot() + 
    annotate("text", x = 0.5, y = 0.5, label = "No overlapping depth bins for comparison") +
    theme_void()
}

# 3. Sample distribution by depth
sample_dist <- profile_data %>%
  ggplot(aes(x = n_obs, y = depth_center, fill = data_source)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c("CTD Observation" = "#2E8B57", "CEFI COBALT Model" = "#FF6347")) +
  scale_y_continuous(trans = "reverse", breaks = seq(0, 200, 25)) +  # Explicit reverse transformation with breaks
  labs(
    title = "Sample Distribution by Depth",
    x = "Number of Observations",
    y = "Depth (m) - Surface to Deep",
    fill = "Data Source"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )

# Combine plots
combined_plot <- (profile_plot | scatter_plot) / sample_dist +
  plot_layout(heights = c(2, 1)) +
  plot_annotation(
    title = "2D CTD-CEFI Chlorophyll Profile Analysis",
    subtitle = "Observational vs Model Chlorophyll-a in the California Current System",
    theme = theme(plot.title = element_text(size = 16, face = "bold"))
  )

# Save the plot
ggsave("2d_ctd_cefi_chlorophyll_profiles.png", combined_plot, 
       width = 14, height = 10, dpi = 300, bg = "white")
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
cat("Generated comprehensive depth profile comparison:\n")
cat("  • Depth profiles with uncertainty bands\n")
cat("  • CTD vs CEFI scatter plot with correlation\n")
cat("  • Sample distribution by depth\n")
cat("File saved as: 2d_ctd_cefi_chlorophyll_profiles.png\n")
