# 05_visualize_3d_chlorophyll.R
# Create 3D visualizations of integrated larval-chlorophyll data

library(readr)
library(dplyr)
library(ggplot2)
library(plotly)
library(viridis)

cat("=== 3D Chlorophyll-Larval Visualization ===\n")

# Load integrated data
integrated_data <- read_csv("calcofi_larval_chlorophyll_complete.csv", show_col_types = FALSE)

cat("✓ Loaded integrated data:", nrow(integrated_data), "records with chlorophyll\n")

# Data summary
cat("\nData Summary:\n")
cat("  Records with CEFI chlorophyll:", sum(!is.na(integrated_data$cefi_chl_mean)), "\n")
cat("  Temporal range:", min(integrated_data$date), "to", max(integrated_data$date), "\n")
cat("  Spatial range:\n")
cat("    Latitude:", round(min(integrated_data$latitude), 2), "to", round(max(integrated_data$latitude), 2), "\n")
cat("    Longitude:", round(min(integrated_data$longitude), 2), "to", round(max(integrated_data$longitude), 2), "\n")

# Create depth-stratified analysis
depth_analysis <- integrated_data %>%
  filter(!is.na(cefi_chl_mean)) %>%
  mutate(
    year = as.numeric(format(date, "%Y")),
    season = case_when(
      format(date, "%m") %in% c("12", "01", "02") ~ "Winter",
      format(date, "%m") %in% c("03", "04", "05") ~ "Spring", 
      format(date, "%m") %in% c("06", "07", "08") ~ "Summer",
      format(date, "%m") %in% c("09", "10", "11") ~ "Fall"
    )
  ) %>%
  select(
    latitude, longitude, year, season, date,
    scientific_name, larvae_100m3,
    cefi_chl_surface, cefi_chl_subsurface, cefi_chl_intermediate, cefi_chl_deep, cefi_chl_mean
  )

cat("\n--- Creating 3D Visualizations ---\n")

# 1. 3D Scatter Plot: Spatial Distribution with Chlorophyll
cat("Creating 3D spatial-chlorophyll plot...\n")

plot_3d_spatial <- plot_ly(
  data = depth_analysis,
  x = ~longitude,
  y = ~latitude, 
  z = ~cefi_chl_mean,
  color = ~larvae_100m3,
  colors = viridis(100),
  type = "scatter3d",
  mode = "markers",
  marker = list(size = 3, opacity = 0.6),
  text = ~paste(
    "Species:", scientific_name,
    "<br>Date:", date,
    "<br>Larvae/100m³:", round(larvae_100m3, 1),
    "<br>Chlorophyll:", round(cefi_chl_mean, 3), "mg/m³"
  ),
  hovertemplate = "%{text}<extra></extra>"
) %>%
layout(
  title = "3D Larval Distribution vs CEFI COBALT Chlorophyll",
  scene = list(
    xaxis = list(title = "Longitude"),
    yaxis = list(title = "Latitude"),
    zaxis = list(title = "Chlorophyll (mg/m³)")
  )
)

# Save 3D plot
htmlwidgets::saveWidget(plot_3d_spatial, "3d_larval_chlorophyll_spatial.html", selfcontained = FALSE)
cat("✓ Saved: 3d_larval_chlorophyll_spatial.html\n")

# 2. Depth-Stratified Chlorophyll Analysis
cat("Creating depth-stratified analysis...\n")

depth_summary <- depth_analysis %>%
  summarise(
    surface_chl = mean(cefi_chl_surface, na.rm = TRUE),
    subsurface_chl = mean(cefi_chl_subsurface, na.rm = TRUE),
    intermediate_chl = mean(cefi_chl_intermediate, na.rm = TRUE),
    deep_chl = mean(cefi_chl_deep, na.rm = TRUE),
    total_larvae = sum(larvae_100m3, na.rm = TRUE),
    .groups = "drop"
  )

# Create depth profile data
depth_profile <- data.frame(
  depth_layer = c("Surface (≤10m)", "Subsurface (10-50m)", "Intermediate (50-100m)", "Deep (100-200m)"),
  depth_midpoint = c(5, 30, 75, 150),
  chlorophyll = c(
    depth_summary$surface_chl,
    depth_summary$subsurface_chl, 
    depth_summary$intermediate_chl,
    depth_summary$deep_chl
  )
)

# 3D Depth Profile Plot
plot_depth_profile <- plot_ly(
  data = depth_profile,
  x = rep(0, 4),  # Single vertical profile
  y = rep(0, 4),
  z = ~depth_midpoint,
  color = ~chlorophyll,
  colors = viridis(100),
  type = "scatter3d",
  mode = "markers+lines",
  marker = list(size = 10),
  line = list(width = 6),
  text = ~paste(
    "Layer:", depth_layer,
    "<br>Depth:", depth_midpoint, "m",
    "<br>Chlorophyll:", round(chlorophyll, 3), "mg/m³"
  ),
  hovertemplate = "%{text}<extra></extra>"
) %>%
layout(
  title = "CEFI COBALT Chlorophyll Depth Profile",
  scene = list(
    xaxis = list(title = ""),
    yaxis = list(title = ""),
    zaxis = list(title = "Depth (m)", autorange = "reversed")
  )
)

htmlwidgets::saveWidget(plot_depth_profile, "3d_chlorophyll_depth_profile.html", selfcontained = FALSE)
cat("✓ Saved: 3d_chlorophyll_depth_profile.html\n")

# 3. Temporal-Spatial Analysis
cat("Creating temporal-spatial analysis...\n")

temporal_summary <- depth_analysis %>%
  group_by(year, season) %>%
  summarise(
    mean_chlorophyll = mean(cefi_chl_mean, na.rm = TRUE),
    total_larvae = sum(larvae_100m3, na.rm = TRUE),
    mean_lat = mean(latitude, na.rm = TRUE),
    mean_lon = mean(longitude, na.rm = TRUE),
    records = n(),
    .groups = "drop"
  ) %>%
  filter(records >= 5)  # Only include seasons with sufficient data

plot_temporal_3d <- plot_ly(
  data = temporal_summary,
  x = ~year,
  y = ~as.numeric(factor(season)),
  z = ~mean_chlorophyll,
  color = ~total_larvae,
  colors = viridis(100),
  type = "scatter3d",
  mode = "markers",
  marker = list(size = 8, opacity = 0.8),
  text = ~paste(
    "Year:", year,
    "<br>Season:", season,
    "<br>Chlorophyll:", round(mean_chlorophyll, 3), "mg/m³",
    "<br>Total Larvae:", round(total_larvae, 1),
    "<br>Records:", records
  ),
  hovertemplate = "%{text}<extra></extra>"
) %>%
layout(
  title = "Temporal Variation in Chlorophyll and Larval Abundance",
  scene = list(
    xaxis = list(title = "Year"),
    yaxis = list(
      title = "Season",
      tickmode = "array",
      tickvals = 1:4,
      ticktext = c("Fall", "Spring", "Summer", "Winter")
    ),
    zaxis = list(title = "Mean Chlorophyll (mg/m³)")
  )
)

htmlwidgets::saveWidget(plot_temporal_3d, "3d_temporal_chlorophyll.html", selfcontained = FALSE)
cat("✓ Saved: 3d_temporal_chlorophyll.html\n")

# 4. Species-Specific Analysis
cat("Creating species-specific analysis...\n")

# Top species by abundance and chlorophyll coverage
top_species <- depth_analysis %>%
  group_by(scientific_name) %>%
  summarise(
    total_larvae = sum(larvae_100m3, na.rm = TRUE),
    mean_chlorophyll = mean(cefi_chl_mean, na.rm = TRUE),
    records = n(),
    .groups = "drop"
  ) %>%
  filter(records >= 20) %>%  # Species with sufficient data
  arrange(desc(total_larvae)) %>%
  head(15)

plot_species_3d <- plot_ly(
  data = top_species,
  x = ~total_larvae,
  y = ~mean_chlorophyll,
  z = ~records,
  color = ~mean_chlorophyll,
  colors = viridis(100),
  type = "scatter3d",
  mode = "markers+text",
  marker = list(size = 8, opacity = 0.8),
  text = ~scientific_name,
  textposition = "top center",
  hovertemplate = paste(
    "Species: %{text}",
    "<br>Total Larvae: %{x}",
    "<br>Mean Chlorophyll: %{y:.3f} mg/m³",
    "<br>Records: %{z}",
    "<extra></extra>"
  )
) %>%
layout(
  title = "Species Distribution: Abundance vs Chlorophyll Environment",
  scene = list(
    xaxis = list(title = "Total Larval Abundance"),
    yaxis = list(title = "Mean Chlorophyll (mg/m³)"),
    zaxis = list(title = "Number of Records")
  )
)

htmlwidgets::saveWidget(plot_species_3d, "3d_species_chlorophyll.html", selfcontained = FALSE)
cat("✓ Saved: 3d_species_chlorophyll.html\n")

# Summary statistics
cat("\n--- Analysis Summary ---\n")
cat("Depth-stratified chlorophyll (mg/m³):\n")
print(depth_profile)

cat("\nTop 5 species by larval abundance:\n")
print(head(top_species[, c("scientific_name", "total_larvae", "mean_chlorophyll")], 5))

cat("\nTemporal coverage:\n")
cat("  Years:", min(temporal_summary$year), "to", max(temporal_summary$year), "\n")
cat("  Seasons represented:", length(unique(temporal_summary$season)), "\n")

# Create summary report
summary_stats <- list(
  total_records = nrow(integrated_data),
  records_with_chlorophyll = nrow(depth_analysis),
  coverage_percent = round(100 * nrow(depth_analysis) / nrow(integrated_data), 1),
  temporal_range = paste(min(integrated_data$date), "to", max(integrated_data$date)),
  species_count = length(unique(depth_analysis$scientific_name)),
  mean_chlorophyll = round(mean(depth_analysis$cefi_chl_mean, na.rm = TRUE), 3),
  depth_profile = depth_profile
)

saveRDS(summary_stats, "3d_analysis_summary.rds")
cat("✓ Saved analysis summary: 3d_analysis_summary.rds\n")

cat("\n🌊 3D Chlorophyll-Larval Visualization Complete!\n")
cat("Generated 4 interactive 3D plots:\n")
cat("  • 3d_larval_chlorophyll_spatial.html\n")
cat("  • 3d_chlorophyll_depth_profile.html\n") 
cat("  • 3d_temporal_chlorophyll.html\n")
cat("  • 3d_species_chlorophyll.html\n")
