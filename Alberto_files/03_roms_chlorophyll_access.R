# ROMS 3D Chlorophyll-a Data Access for CalCOFI Larval Analysis
# Extracts chlorophyll-a data from ROMS model using CalCOFI spatial-temporal bounds
# Follows real-data-only rule - uses actual oceanographic model output

library(ncdf4)
library(dplyr)
library(readr)
library(lubridate)
library(httr)

cat("=== ROMS 3D Chlorophyll-a Data Access ===\n")

# Function to load CalCOFI bounds
load_calcofi_bounds <- function(bounds_file = "calcofi_larval_bounds.rds") {
  if (!file.exists(bounds_file)) {
    cat("✗ Bounds file not found:", bounds_file, "\n")
    cat("Please run 02_extract_larval_bounds.R first\n")
    return(NULL)
  }
  
  bounds <- readRDS(bounds_file)
  cat("✓ Loaded CalCOFI bounds from", bounds_file, "\n")
  return(bounds)
}

# Function to access ROMS chlorophyll data via ERDDAP
access_roms_chlorophyll_erddap <- function(bounds) {
  cat("\n--- Accessing ROMS Chlorophyll via ERDDAP ---\n")
  
  # SCCOOS ROMS ERDDAP endpoint (based on search results)
  base_url <- "https://erddap.sccoos.org/erddap/griddap/roms_ncst"
  
  # Convert bounds to ERDDAP format
  # Note: ERDDAP uses longitude in 0-360 format (232.5-243.0 from metadata)
  lon_min <- bounds$lon_min + 360  # Convert from -180:180 to 0:360
  lon_max <- bounds$lon_max + 360
  
  # Format dates for ERDDAP (ISO format)
  date_min <- format(bounds$date_min, "%Y-%m-%dT00:00:00Z")
  date_max <- format(bounds$date_max, "%Y-%m-%dT23:59:59Z")
  
  cat("ERDDAP parameters:\n")
  cat("Longitude:", lon_min, "to", lon_max, "\n")
  cat("Latitude:", bounds$lat_min, "to", bounds$lat_max, "\n")
  cat("Date range:", date_min, "to", date_max, "\n")
  cat("Depth range: 0 to", bounds$depth_max, "m\n")
  
  # Check if chlorophyll variable exists in this dataset
  # From metadata, this dataset has temp, salt, u, v but no chlorophyll
  cat("⚠️  SCCOOS ROMS dataset appears to be physical-only (temp, salt, currents)\n")
  cat("⚠️  No chlorophyll variables found in metadata\n")
  
  return(NULL)
}

# Function to search for biogeochemical ROMS datasets
search_biogeochemical_roms <- function() {
  cat("\n--- Searching for Biogeochemical ROMS Datasets ---\n")
  
  # Known potential sources for California Current biogeochemical ROMS
  potential_sources <- list(
    "UCSC_ROMS" = list(
      description = "UCSC California Current System ROMS",
      note = "May have biogeochemical variables including chlorophyll"
    ),
    "CeNCOOS_Bio" = list(
      description = "CeNCOOS Biogeochemical ROMS",
      note = "Extension of physical ROMS with ecosystem components"
    ),
    "NOAA_CEFI" = list(
      description = "NOAA CEFI Regional Models",
      note = "Climate Ecosystem and Fisheries Initiative models"
    )
  )
  
  cat("Potential biogeochemical ROMS sources:\n")
  for (name in names(potential_sources)) {
    source <- potential_sources[[name]]
    cat("•", name, ":", source$description, "\n")
    cat("  ", source$note, "\n")
  }
  
  return(potential_sources)
}

# Function removed - violates real-data-only rule
# create_depth_chlorophyll_profile <- function(bounds, sampling_data) {
#   # REMOVED: Synthetic chlorophyll generation violates real-data-only rule
#   cat("✗ Synthetic chlorophyll generation removed - violates real-data-only rule\n")
#   return(NULL)
# }

# Function to access real ROMS chlorophyll data only
access_real_roms_chlorophyll <- function(bounds) {
  cat("\n--- Accessing Real ROMS Chlorophyll Data ---\n")
  cat("⚠️  No real ROMS chlorophyll data sources currently available\n")
  cat("⚠️  SCCOOS ROMS dataset is physical-only (no biogeochemical variables)\n")
  cat("⚠️  Following real-data-only rule - no synthetic data generation\n")
  
  # List potential real data sources for future implementation
  cat("\nPotential real ROMS biogeochemical data sources:\n")
  cat("• NOAA CEFI California Current models\n")
  cat("• UCSC California Current System ROMS with biogeochemistry\n")
  cat("• CeNCOOS biogeochemical extensions\n")
  
  return(NULL)
}

# Function to match chlorophyll with larval data
match_chlorophyll_with_larvae <- function(chlorophyll_data, larval_file = "Larvae.csv") {
  cat("\n--- Matching Chlorophyll with Larval Data ---\n")
  
  if (is.null(chlorophyll_data)) {
    cat("✗ No chlorophyll data available for matching\n")
    return(NULL)
  }
  
  # Load larval data
  larval_data <- read_csv(larval_file, show_col_types = FALSE)
  
  # For each larval record, find nearest chlorophyll values at different depths
  # This creates a 3D context for each larval sample
  matched_data <- larval_data %>%
    left_join(
      chlorophyll_data,
      by = c("latitude", "longitude"),
      relationship = "many-to-many"
    ) %>%
    filter(!is.na(chlorophyll_mg_m3)) %>%
    arrange(cruise, latitude, longitude, depth)
  
  cat("✓ Matched", nrow(matched_data), "larval-chlorophyll records\n")
  
  # Summary by depth zones
  depth_summary <- matched_data %>%
    mutate(
      depth_zone = case_when(
        depth <= 10 ~ "Surface (0-10m)",
        depth <= 50 ~ "Subsurface (10-50m)",
        depth <= 100 ~ "Intermediate (50-100m)",
        TRUE ~ "Deep (>100m)"
      )
    ) %>%
    group_by(depth_zone) %>%
    summarise(
      n_records = n(),
      mean_chlorophyll = mean(chlorophyll_mg_m3, na.rm = TRUE),
      mean_larvae_density = mean(larvae_100m3, na.rm = TRUE),
      .groups = 'drop'
    )
  
  cat("\nChlorophyll by depth zone:\n")
  print(depth_summary)
  
  return(matched_data)
}

# Main execution function
main_roms_chlorophyll_access <- function() {
  cat("Starting ROMS 3D chlorophyll-a data access for CalCOFI analysis...\n\n")
  
  # Load CalCOFI bounds
  bounds <- load_calcofi_bounds()
  if (is.null(bounds)) return(NULL)
  
  # Try ERDDAP access first
  roms_data <- access_roms_chlorophyll_erddap(bounds)
  
  # Search for alternative sources
  sources <- search_biogeochemical_roms()
  
  # Access real ROMS chlorophyll data only
  chlorophyll_data <- access_real_roms_chlorophyll(bounds)
  
  # Match with larval data (will return NULL if no real data available)
  matched_data <- match_chlorophyll_with_larvae(chlorophyll_data)
  
  if (!is.null(matched_data)) {
    # Save matched data
    output_file <- "calcofi_larval_chlorophyll_3d.csv"
    write_csv(matched_data, output_file)
    cat("✓ Saved 3D larval-chlorophyll data:", output_file, "\n")
    
    # Create summary
    summary_stats <- matched_data %>%
      group_by(scientific_name, depth) %>%
      summarise(
        n_samples = n(),
        mean_chlorophyll = mean(chlorophyll_mg_m3, na.rm = TRUE),
        mean_larvae_density = mean(larvae_100m3, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      arrange(scientific_name, depth)
    
    summary_file <- "larval_chlorophyll_summary.csv"
    write_csv(summary_stats, summary_file)
    cat("✓ Saved species-depth summary:", summary_file, "\n")
  }
  
  cat("\n--- Next Steps ---\n")
  cat("1. Investigate UCSC ROMS biogeochemical model access\n")
  cat("2. Check NOAA CEFI regional models for California Current\n")
  cat("3. Consider satellite chlorophyll data as alternative\n")
  cat("4. Use CTD chlorophyll data from script 05 for real observations\n")
  cat("⚠️  No ROMS chlorophyll data generated - following real-data-only rule\n")
  
  return(list(
    bounds = bounds,
    chlorophyll_data = chlorophyll_data,
    matched_data = matched_data
  ))
}

# Execute
if (interactive() || !exists("skip_main_execution")) {
  roms_results <- main_roms_chlorophyll_access()
  cat("\n🌊 ROMS chlorophyll-a access completed!\n")
}
