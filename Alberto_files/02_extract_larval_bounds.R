# Extract Spatial-Temporal Bounds from CalCOFI Larval Data
# Creates bounding box and date range for ROMS chlorophyll-a data access
# Follows real-data-only rule - uses actual larval sampling locations and dates

library(dplyr)
library(readr)
library(lubridate)

cat("=== CalCOFI Larval Data Bounds Extraction ===\n")

# Function to extract spatial-temporal bounds from larval data
extract_larval_bounds <- function(larval_file = "Larvae.csv") {
  if (!file.exists(larval_file)) {
    cat("✗ Larval data file not found:", larval_file, "\n")
    cat("Please run create_larval_datasets.R first\n")
    return(NULL)
  }
  
  cat("Loading real larval data...\n")
  larval_data <- read_csv(larval_file, show_col_types = FALSE)
  cat("✓ Loaded", nrow(larval_data), "larval records\n")
  
  # Extract spatial bounds
  spatial_bounds <- larval_data %>%
    summarise(
      lat_min = min(latitude, na.rm = TRUE),
      lat_max = max(latitude, na.rm = TRUE),
      lon_min = min(longitude, na.rm = TRUE),
      lon_max = max(longitude, na.rm = TRUE),
      n_locations = n_distinct(paste(latitude, longitude))
    )
  
  cat("\n--- Spatial Bounds ---\n")
  cat("Latitude range:", spatial_bounds$lat_min, "to", spatial_bounds$lat_max, "\n")
  cat("Longitude range:", spatial_bounds$lon_min, "to", spatial_bounds$lon_max, "\n")
  cat("Unique locations:", spatial_bounds$n_locations, "\n")
  
  # Extract temporal bounds
  temporal_bounds <- larval_data %>%
    mutate(sample_date = as.Date(time)) %>%
    summarise(
      date_min = min(sample_date, na.rm = TRUE),
      date_max = max(sample_date, na.rm = TRUE),
      n_dates = n_distinct(sample_date)
    )
  
  cat("\n--- Temporal Bounds ---\n")
  cat("Date range:", temporal_bounds$date_min, "to", temporal_bounds$date_max, "\n")
  cat("Unique sampling dates:", temporal_bounds$n_dates, "\n")
  
  # Extract tow information
  tow_bounds <- larval_data %>%
    summarise(
      tow_min = min(tow_number, na.rm = TRUE),
      tow_max = max(tow_number, na.rm = TRUE),
      n_tows = n_distinct(tow_number)
    )
  
  cat("\n--- Tow Information ---\n")
  cat("Tow number range:", tow_bounds$tow_min, "to", tow_bounds$tow_max, "\n")
  cat("Unique tow numbers:", tow_bounds$n_tows, "\n")
  
  # Create ROMS bounding box with buffer
  buffer_deg <- 0.5  # 0.5 degree buffer around larval sampling area
  buffer_days <- 7   # 7 day buffer around sampling dates
  
  roms_bounds <- list(
    # Spatial bounds with buffer
    lat_min = spatial_bounds$lat_min - buffer_deg,
    lat_max = spatial_bounds$lat_max + buffer_deg,
    lon_min = spatial_bounds$lon_min - buffer_deg,
    lon_max = spatial_bounds$lon_max + buffer_deg,
    
    # Temporal bounds with buffer
    date_min = temporal_bounds$date_min - days(buffer_days),
    date_max = temporal_bounds$date_max + days(buffer_days),
    
    # Depth bounds for ROMS vertical levels
    depth_min = 0,  # Surface
    depth_max = 200,  # Standard depth for larval analysis
    
    # Original bounds (no buffer)
    original = list(
      spatial = spatial_bounds,
      temporal = temporal_bounds,
      tow = tow_bounds
    )
  )
  
  cat("\n--- ROMS Bounding Box (with", buffer_deg, "° and", buffer_days, "day buffers) ---\n")
  cat("Latitude:", roms_bounds$lat_min, "to", roms_bounds$lat_max, "\n")
  cat("Longitude:", roms_bounds$lon_min, "to", roms_bounds$lon_max, "\n")
  cat("Date range:", roms_bounds$date_min, "to", roms_bounds$date_max, "\n")
  cat("Depth range: 0 to", roms_bounds$depth_max, "m\n")
  
  return(roms_bounds)
}

# Function to create unique sampling locations summary
create_sampling_summary <- function(larval_file = "Larvae.csv") {
  larval_data <- read_csv(larval_file, show_col_types = FALSE)
  
  sampling_summary <- larval_data %>%
    group_by(latitude, longitude, cruise, time) %>%
    summarise(
      station_id = first(station),
      tow_numbers = paste(unique(tow_number), collapse = ","),
      species_count = n_distinct(scientific_name),
      total_larvae = sum(larvae_count, na.rm = TRUE),
      sample_date = as.Date(first(time)),
      .groups = 'drop'
    ) %>%
    arrange(sample_date, latitude, longitude)
  
  cat("\n--- Sampling Locations Summary ---\n")
  cat("Unique sampling events:", nrow(sampling_summary), "\n")
  
  # Show first few locations
  cat("Sample locations:\n")
  print(head(sampling_summary %>% 
    select(latitude, longitude, sample_date, species_count, total_larvae), 10))
  
  return(sampling_summary)
}

# Main execution function
main_bounds_extraction <- function() {
  cat("Starting CalCOFI larval bounds extraction for ROMS access...\n\n")
  
  # Extract bounds
  bounds <- extract_larval_bounds()
  
  if (is.null(bounds)) {
    cat("Cannot proceed without larval data\n")
    return(NULL)
  }
  
  # Create sampling summary
  sampling_summary <- create_sampling_summary()
  
  # Save bounds for ROMS access
  bounds_file <- "calcofi_larval_bounds.rds"
  saveRDS(bounds, bounds_file)
  cat("✓ Saved bounds data:", bounds_file, "\n")
  
  # Save sampling summary
  summary_file <- "calcofi_sampling_summary.csv"
  write_csv(sampling_summary, summary_file)
  cat("✓ Saved sampling summary:", summary_file, "\n")
  
  # Create ROMS access parameters
  cat("\n--- ROMS Access Parameters ---\n")
  cat("Use these parameters for ROMS chlorophyll-a data extraction:\n")
  cat("lat_range <- c(", bounds$lat_min, ",", bounds$lat_max, ")\n")
  cat("lon_range <- c(", bounds$lon_min, ",", bounds$lon_max, ")\n")
  cat("date_range <- c('", bounds$date_min, "', '", bounds$date_max, "')\n")
  cat("depth_range <- c(", bounds$depth_min, ",", bounds$depth_max, ")\n")
  
  return(list(bounds = bounds, sampling = sampling_summary))
}

# Execute
if (interactive() || !exists("skip_main_execution")) {
  larval_bounds <- main_bounds_extraction()
  cat("\n📍 CalCOFI larval bounds extraction completed!\n")
}
