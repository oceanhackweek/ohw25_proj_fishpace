# Unified 3D Spatial Visualization: CEFI Chlorophyll + CTD Chlorophyll + Larval Abundance
# Single 3D plot showing all three data components with depth

library(dplyr)
library(readr)
library(plotly)
library(viridis)
library(htmlwidgets)

cat("=== Unified 3D Spatial Chlorophyll-Larval Visualization ===\n")

# Load all datasets
cat("Loading datasets...\n")
integrated_data <- read_csv("calcofi_larval_chlorophyll_complete.csv")
cefi_data <- read_csv("cefi_cobalt_chlorophyll_3d.csv")

# Check if CTD data exists
ctd_file <- "calcofi_bottles_recent.csv"
if (file.exists(ctd_file)) {
  ctd_data <- read_csv(ctd_file)
  has_ctd <- TRUE
  cat("✓ Loaded CTD data:", nrow(ctd_data), "records\n")
} else {
  has_ctd <- FALSE
  cat("! CTD data not found, using CEFI only\n")
}

cat("✓ Loaded integrated data:", nrow(integrated_data), "larval records\n")
cat("✓ Loaded CEFI data:", nrow(cefi_data), "chlorophyll records\n")

# Prepare larval data with depth information
larval_3d <- integrated_data %>%
  filter(!is.na(cefi_chl_mean), !is.na(larvae_100m3)) %>%
  mutate(
    # Fixed representative depths per tow type (Bottom_D is seafloor depth, not tow depth)
    depth_m = case_when(
      tow_type == "CB" ~ 35,    # CalCOFI Bongo: typical oblique tow depth
      tow_type == "MT" ~ 15,    # Manta tow: near-surface
      tow_type == "PV" ~ 5,     # Plankton vertical: surface
      tow_type == "Surface" ~ 5,
      tow_type == "Oblique" ~ 60,  # Oblique tows: deeper
      TRUE ~ 30  # Default depth
    ),
    data_type = "Larval Abundance",
    value = larvae_100m3,
    color_var = cefi_chl_mean,  # Use chlorophyll for color
    size_var = pmin(larvae_100m3, 100)  # Cap larval counts for reasonable marker sizes
  ) %>%
  select(longitude, latitude, depth_m, data_type, value, color_var, size_var, scientific_name)

# Prepare CEFI chlorophyll data (subsample for performance)
cefi_3d <- cefi_data %>%
  filter(!is.na(chlorophyll_mg_m3), depth_m <= 200) %>%
  sample_n(min(3000, nrow(.))) %>%
  mutate(
    data_type = "CEFI Chlorophyll",
    value = chlorophyll_mg_m3,
    color_var = chlorophyll_mg_m3,
    size_var = 8,  # Larger size for better visibility
    scientific_name = "Model Data"
  ) %>%
  select(longitude, latitude, depth_m, data_type, value, color_var, size_var, scientific_name)

# Prepare CTD chlorophyll data if available
if (has_ctd) {
  ctd_3d <- ctd_data %>%
    filter(!is.na(chlorophyll_mg_m3), !is.na(depth_m), depth_m <= 200) %>%
    # Filter to California Current region
    filter(longitude >= -130, longitude <= -115, latitude >= 28, latitude <= 42) %>%
    sample_n(min(2000, nrow(.))) %>%
    mutate(
      data_type = "CTD Chlorophyll",
      value = chlorophyll_mg_m3,
      color_var = chlorophyll_mg_m3,
      size_var = 5,  # Fixed medium size for CTD points
      scientific_name = "CTD Observation"
    ) %>%
    select(longitude, latitude, depth_m, data_type, value, color_var, size_var, scientific_name)
  
  # Combine all datasets
  combined_3d <- bind_rows(larval_3d, cefi_3d, ctd_3d)
  cat("✓ Combined datasets with CTD:", nrow(combined_3d), "total points\n")
} else {
  # Combine without CTD
  combined_3d <- bind_rows(larval_3d, cefi_3d)
  cat("✓ Combined datasets without CTD:", nrow(combined_3d), "total points\n")
}

# Create unified 3D visualization
cat("Creating unified 3D spatial visualization...\n")

# Define symbols for each data type
symbol_palette <- list(
  "Larval Abundance" = "circle",
  "CEFI Chlorophyll" = "square",
  "CTD Chlorophyll" = "diamond"
)

# Get global chlorophyll range for consistent color scale
chl_range <- range(combined_3d$color_var, na.rm = TRUE)
cat("Chlorophyll range for color scale:", round(chl_range[1], 3), "to", round(chl_range[2], 3), "mg/m³\n")

# Create the plot
unified_plot <- plot_ly()

# Add each data type as separate trace for better control
for (data_type in unique(combined_3d$data_type)) {
  data_subset <- combined_3d %>% filter(data_type == !!data_type)
  
  # Determine opacity
  opacity <- case_when(
    data_type == "Larval Abundance" ~ 0.9,
    data_type == "CEFI Chlorophyll" ~ 0.8,  # Increased opacity for better visibility
    data_type == "CTD Chlorophyll" ~ 0.7,
    TRUE ~ 0.6
  )
  
  unified_plot <- unified_plot %>%
    add_trace(
      data = data_subset,
      x = ~longitude,
      y = ~latitude, 
      z = ~depth_m,  # Positive depth - surface at top, deeper values below
      color = ~color_var,
      colors = "viridis",  # Use same color scale for all (chlorophyll)
      cmin = chl_range[1],  # Set consistent color scale
      cmax = chl_range[2],
      type = "scatter3d",
      mode = "markers",
      name = data_type,
      marker = list(
        size = ~size_var,  # Use size_var for marker sizes
        opacity = opacity,
        symbol = symbol_palette[[data_type]],
        line = list(width = 0.5, color = "black"),
        sizemode = "diameter",
        sizeref = 2
      ),
      text = ~paste(
        "Type:", data_type,
        "<br>Location:", round(latitude, 2), "°N,", round(longitude, 2), "°W",
        "<br>Depth:", round(depth_m, 1), "m",
        "<br>Chlorophyll:", round(color_var, 3), "mg/m³",
        ifelse(data_type == "Larval Abundance", 
               paste("<br>Larval Count:", round(value, 1), "<br>Species:", scientific_name), 
               paste("<br>Value:", round(value, 3)))
      ),
      hovertemplate = "%{text}<extra></extra>",
      showlegend = TRUE
    )
}

# Layout and styling
unified_plot <- unified_plot %>%
  layout(
    title = list(
      text = "3D Chlorophyll Environment with Larval Fish Distribution<br>Color: Chlorophyll-a (mg/m³) | Size: Larval Abundance",
      font = list(size = 16)
    ),
    scene = list(
      xaxis = list(
        title = "Longitude (°W)",
        titlefont = list(size = 12)
      ),
      yaxis = list(
        title = "Latitude (°N)", 
        titlefont = list(size = 12)
      ),
      zaxis = list(
        title = "Depth (m)",
        titlefont = list(size = 12),
        autorange = "reversed"  # Surface (0m) at top, deeper values below
      ),
      camera = list(
        eye = list(x = 1.5, y = 1.5, z = 1.2)
      ),
      aspectmode = "manual",
      aspectratio = list(x = 1, y = 1, z = 0.8)
    ),
    legend = list(
      x = 0.02,
      y = 0.98,
      bgcolor = "rgba(255,255,255,0.8)",
      bordercolor = "black",
      borderwidth = 1,
      title = list(text = "Chlorophyll-a (mg/m³)")
    ),
    margin = list(l = 0, r = 0, b = 0, t = 50)
  )

# Save the visualization
htmlwidgets::saveWidget(unified_plot, "unified_3d_chlorophyll_larval_spatial.html", selfcontained = FALSE)
cat("✓ Saved: unified_3d_chlorophyll_larval_spatial.html\n")

# Generate summary statistics
cat("\n--- Unified 3D Analysis Summary ---\n")
summary_stats <- combined_3d %>%
  group_by(data_type) %>%
  summarise(
    n_points = n(),
    depth_range = paste(round(min(depth_m, na.rm = TRUE), 1), "-", 
                       round(max(depth_m, na.rm = TRUE), 1), "m"),
    value_range = paste(round(min(value, na.rm = TRUE), 3), "-", 
                       round(max(value, na.rm = TRUE), 3)),
    mean_value = round(mean(value, na.rm = TRUE), 3),
    .groups = "drop"
  )

print(summary_stats)

# Spatial coverage
spatial_summary <- combined_3d %>%
  summarise(
    lon_range = paste(round(min(longitude, na.rm = TRUE), 2), "to", 
                     round(max(longitude, na.rm = TRUE), 2), "°W"),
    lat_range = paste(round(min(latitude, na.rm = TRUE), 2), "to", 
                     round(max(latitude, na.rm = TRUE), 2), "°N"),
    depth_range = paste(round(min(depth_m, na.rm = TRUE), 1), "to", 
                       round(max(depth_m, na.rm = TRUE), 1), "m")
  )

cat("\nSpatial Coverage:\n")
cat("  Longitude:", spatial_summary$lon_range, "\n")
cat("  Latitude:", spatial_summary$lat_range, "\n") 
cat("  Depth:", spatial_summary$depth_range, "\n")

cat("\n🌊 Unified 3D Spatial Visualization Complete!\n")
cat("Interactive 3D chlorophyll environment with larval distribution:\n")
cat("  • Color scale: Chlorophyll-a concentration (mg/m³) - Viridis palette\n")
cat("  • Circles: Larval abundance (size = larval count)\n")
cat("  • Squares: CEFI COBALT chlorophyll model data (small fixed size)\n")
if (has_ctd) {
  cat("  • Diamonds: CTD chlorophyll observations (medium fixed size)\n")
}
cat("File saved as: unified_3d_chlorophyll_larval_spatial.html\n")
