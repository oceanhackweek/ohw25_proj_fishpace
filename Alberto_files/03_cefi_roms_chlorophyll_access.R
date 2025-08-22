# CEFI Regional MOM6 COBALT Chlorophyll Access - Fixed Version
# Access real 3D chlorophyll data from NOAA CEFI Regional MOM6 COBALT biogeochemical model

library(dplyr)
library(readr)
library(lubridate)
library(ncdf4)
library(httr)

cat("=== CEFI Regional MOM6 COBALT Chlorophyll Access ===\n")
cat("Starting CEFI Regional MOM6 COBALT chlorophyll access...\n\n")

# Load larval data to determine spatial and temporal bounds
larval_data <- read_csv("Larvae.csv", show_col_types = FALSE)

# Filter larval data to CEFI temporal coverage (1993-2024)
larval_data <- larval_data %>%
  filter(year(date) >= 1993, year(date) <= 2024)

cat("✓ Loaded larval data:", nrow(larval_data), "records (1993-2024)\n")

# CEFI COBALT dataset URL (regrid version for easier access)
cefi_url <- "http://psl.noaa.gov/thredds/dodsC/Projects/CEFI/regional_mom6/cefi_portal/northeast_pacific/full_domain/hindcast/monthly/regrid/r20250509/chl.nep.full.hcast.monthly.regrid.r20250509.199301-202412.nc"

cat("CEFI COBALT dataset:\n")
cat("  Region: Northeast Pacific\n")
cat("  Domain: Full\n")
cat("  Frequency: Monthly\n")
cat("  Variable: Chlorophyll - 3D (chl)\n")
cat("  Depth range: 0-200m\n")
cat("  URL:", cefi_url, "\n")

# Open NetCDF connection directly (skip HTTP HEAD check that was causing issues)
cat("\nOpening CEFI COBALT NetCDF connection...\n")
tryCatch({
  nc <- nc_open(cefi_url)
  cat("✓ CEFI COBALT dataset accessible\n")
}, error = function(e) {
  cat("✗ CEFI COBALT connection failed:", e$message, "\n")
  quit(status = 1)
})

# Get coordinate variables
lon_var <- ncvar_get(nc, "lon")
lat_var <- ncvar_get(nc, "lat")
time_var <- ncvar_get(nc, "time")
depth_var <- ncvar_get(nc, "z_l")

cat("\nDataset dimensions:\n")
cat("  Longitude points:", length(lon_var), "\n")
cat("  Latitude points:", length(lat_var), "\n")
cat("  Depth levels:", length(depth_var), "\n")
cat("  Time steps:", length(time_var), "\n")

# Convert time to dates - CEFI uses days since 1900-01-01 but values are negative
# This suggests a different time origin, let's try 2000-01-01
time_origin <- as.Date("2000-01-01")
time_dates <- time_origin + time_var

cat("Coordinate ranges (original):\n")
cat("  Longitude:", min(lon_var), "to", max(lon_var), "\n")
cat("  Latitude:", min(lat_var), "to", max(lat_var), "\n")
cat("  Depth:", min(depth_var), "to", max(depth_var), "m\n")
cat("  Time values:", min(time_var), "to", max(time_var), "\n")
cat("  Time (interpreted):", min(time_dates), "to", max(time_dates), "\n")

# Define spatial bounds for California Current region
# CEFI uses 0-360° longitude, so convert our -130 to -115.7° bounds
lon_min_360 <- (-130) + 360  # 230°
lon_max_360 <- (-115.7033) + 360  # 244.3°
lat_min <- 28
lat_max <- 42

cat("Target region (CEFI coordinates):\n")
cat("  Longitude:", lon_min_360, "to", lon_max_360, "\n")
cat("  Latitude:", lat_min, "to", lat_max, "\n")

# Find spatial indices for California Current region
lon_idx <- which(lon_var >= lon_min_360 & lon_var <= lon_max_360)
lat_idx <- which(lat_var >= lat_min & lat_var <= lat_max)
depth_idx <- which(depth_var >= 0 & depth_var <= 200)

# Find temporal indices - use available time range from the dataset
available_years <- year(time_dates)
cat("Available years:", min(available_years), "to", max(available_years), "\n")

# Use larval data years that overlap with CEFI data
larval_years <- unique(year(larval_data$date))
overlap_years <- intersect(larval_years, available_years)
cat("Overlapping years:", min(overlap_years), "to", max(overlap_years), "\n")

# Sample recent years for efficiency (every 12 months)
time_idx <- which(year(time_dates) %in% overlap_years)
if (length(time_idx) > 24) {
  # Sample every 12 months if we have many time points
  time_sample_idx <- time_idx[seq(1, length(time_idx), by = 12)]
} else {
  # Use all available time points if we don't have many
  time_sample_idx <- time_idx
}

cat("\nSpatial subset:\n")
cat("  Longitude indices:", length(lon_idx), "points\n")
cat("  Latitude indices:", length(lat_idx), "points\n")
cat("  Depth indices:", length(depth_idx), "levels (0-200m)\n")
cat("  Time indices:", length(time_sample_idx), "samples (annual)\n")

if (length(time_sample_idx) == 0) {
  cat("✗ No temporal data within specified range\n")
  nc_close(nc)
  quit(status = 1)
}

# Extract chlorophyll data in small chunks
cat("\nExtracting chlorophyll data...\n")

all_chl_data <- list()

for (i in seq_along(time_sample_idx)) {
  t_idx <- time_sample_idx[i]
  time_val <- time_dates[t_idx]
  
  cat("  Processing time step", i, "of", length(time_sample_idx), "(", time_val, ")...\n")
  
  # Extract one time slice at a time to avoid memory issues
  # 4D data: [lon, lat, depth, time]
  chl_slice <- ncvar_get(nc, "chl",
                        start = c(min(lon_idx), min(lat_idx), min(depth_idx), t_idx),
                        count = c(length(lon_idx), length(lat_idx), length(depth_idx), 1))
  
  cat("    Extracted data dimensions:", dim(chl_slice), "\n")
  
  # Convert to data frame
  for (d in seq_along(depth_idx)) {
    depth_val <- depth_var[depth_idx[d]]
    
    # Handle different dimension structures
    if (length(dim(chl_slice)) == 4) {
      chl_2d <- chl_slice[, , d, 1]  # 4D: [lon, lat, depth, time]
    } else if (length(dim(chl_slice)) == 3) {
      chl_2d <- chl_slice[, , d]     # 3D: [lon, lat, depth] 
    } else {
      cat("    Unexpected data dimensions, skipping...\n")
      next
    }
    
    # Create data frame for this depth slice
    slice_df <- expand.grid(
      lon_i = seq_along(lon_idx),
      lat_i = seq_along(lat_idx)
    ) %>%
      mutate(
        longitude_360 = lon_var[lon_idx[lon_i]],
        longitude = ifelse(longitude_360 > 180, longitude_360 - 360, longitude_360),  # Convert back to -180:180
        latitude = lat_var[lat_idx[lat_i]],
        depth_m = depth_val,
        time = time_val,
        chlorophyll_mg_m3 = as.vector(chl_2d)
      ) %>%
      filter(!is.na(chlorophyll_mg_m3), 
             chlorophyll_mg_m3 > 0, 
             chlorophyll_mg_m3 < 100) %>%
      select(longitude, latitude, depth_m, time, chlorophyll_mg_m3)
    
    if (nrow(slice_df) > 0) {
      all_chl_data[[length(all_chl_data) + 1]] <- slice_df
    }
  }
}

# Close NetCDF connection
nc_close(nc)

# Combine all data
if (length(all_chl_data) > 0) {
  cefi_chl_data <- bind_rows(all_chl_data)
  
  cat("\n✓ CEFI COBALT chlorophyll extraction completed\n")
  cat("Data summary:\n")
  cat("  Total records:", nrow(cefi_chl_data), "\n")
  cat("  Chlorophyll range:", min(cefi_chl_data$chlorophyll_mg_m3), "to", 
      max(cefi_chl_data$chlorophyll_mg_m3), "mg/m³\n")
  cat("  Depth range:", min(cefi_chl_data$depth_m), "to", 
      max(cefi_chl_data$depth_m), "m\n")
  cat("  Time range:", min(cefi_chl_data$time), "to", 
      max(cefi_chl_data$time), "\n")
  
  # Ensure all columns are atomic (not lists) before saving
  cefi_chl_data <- cefi_chl_data %>%
    mutate(
      longitude = as.numeric(longitude),
      latitude = as.numeric(latitude),
      depth_m = as.numeric(depth_m),
      time = as.numeric(time),
      chlorophyll_mg_m3 = as.numeric(chlorophyll_mg_m3)
    )
  
  # Save CEFI chlorophyll data
  write_csv(cefi_chl_data, "cefi_cobalt_chlorophyll_3d.csv")
  cat("✓ Saved CEFI COBALT chlorophyll data to: cefi_cobalt_chlorophyll_3d.csv\n")
  
} else {
  cat("✗ No valid chlorophyll data extracted\n")
  quit(status = 1)
}

cat("\n=== CEFI COBALT Chlorophyll Access Complete ===\n")
