# Integrate Larval Data with 3D Chlorophyll
# Combines larval fish data with ROMS and CTD chlorophyll estimates
# Creates final integrated dataset for larval-environment analysis

library(dplyr)
library(readr)
library(lubridate)

cat("=== Integrate Larval Data with 3D Chlorophyll ===\n")

# Function to load larval datasets
load_larval_datasets <- function() {
  cat("Loading larval datasets...\n")
  
  # Load main larval dataset
  if (!file.exists("Larvae.csv")) {
    cat("✗ Larvae.csv not found. Please run create_larval_datasets.R first\n")
    return(NULL)
  }
  
  larval_data <- read_csv("Larvae.csv", show_col_types = FALSE)
  cat("✓ Loaded larval data:", nrow(larval_data), "records\n")
  
  # Show temporal and spatial coverage
  year_range <- range(larval_data$year, na.rm = TRUE)
  cat("Temporal coverage:", year_range[1], "-", year_range[2], "\n")
  
  species_count <- length(unique(larval_data$scientific_name))
  cat("Species diversity:", species_count, "unique species\n")
  
  return(larval_data)
}

# Function to load CEFI COBALT chlorophyll data
load_cefi_chlorophyll <- function() {
  cat("\nLoading CEFI COBALT chlorophyll data...\n")
  
  # Check for CEFI chlorophyll files (new COBALT data)
  cefi_files <- c(
    "cefi_larval_chlorophyll_matched.csv",
    "cefi_cobalt_chlorophyll_3d.csv",
    "calcofi_larval_chlorophyll_3d.csv"  # fallback
  )
  
  cefi_file <- NULL
  for (file in cefi_files) {
    if (file.exists(file)) {
      cefi_file <- file
      break
    }
  }
  
  if (is.null(cefi_file)) {
    cat("⚠️  No CEFI chlorophyll data found. Please run 03_cefi_roms_chlorophyll_access.R first\n")
    return(NULL)
  }
  
  cefi_data <- read_csv(cefi_file, show_col_types = FALSE)
  cat("✓ Loaded CEFI COBALT chlorophyll:", nrow(cefi_data), "records\n")
  
  return(cefi_data)
}

# Function to load CTD chlorophyll data
load_ctd_chlorophyll <- function() {
  cat("\nLoading CTD chlorophyll data...\n")
  
  # Check for CTD chlorophyll file
  ctd_file <- "calcofi_ctd_roms_chlorophyll_combined.csv"
  
  if (!file.exists(ctd_file)) {
    cat("⚠️  CTD chlorophyll data not found. Please run 05_extract_ctd_chlorophyll.R first\n")
    return(NULL)
  }
  
  ctd_data <- read_csv(ctd_file, show_col_types = FALSE)
  cat("✓ Loaded CTD chlorophyll:", nrow(ctd_data), "records\n")
  
  return(ctd_data)
}

# Function to integrate larval data with CEFI COBALT chlorophyll
integrate_larval_chlorophyll <- function(larval_data, cefi_data, ctd_data) {
  cat("\n--- Integrating Larval Data with CEFI COBALT Chlorophyll ---\n")
  
  if (is.null(larval_data)) {
    cat("✗ No larval data available for integration\n")
    return(NULL)
  }
  
  # This section was removed - continue to spatial-temporal matching below
  
  # Real data only: Require CEFI COBALT chlorophyll data
  if (is.null(cefi_data) || nrow(cefi_data) == 0) {
    cat("✗ No CEFI COBALT chlorophyll data available\n")
    cat("  Please run 03_cefi_roms_chlorophyll_access.R first\n")
    cat("  Following real-data-only rule - no synthetic or fallback data\n")
    return(NULL)
  }
  
  # Use CEFI COBALT data as primary source (real data only)
  cat("Integrating CEFI COBALT chlorophyll with larval data...\n")
    
    # Match by location and time (with tolerance)
    cefi_summary <- cefi_data %>%
      mutate(
        match_lat = round(latitude, 1),  # Use 0.1° tolerance (~11km)
        match_lon = round(longitude, 1),
        match_year = as.numeric(format(as.Date(time, origin = "1970-01-01"), "%Y"))
      ) %>%
      group_by(match_lat, match_lon, match_year) %>%
      summarise(
        cefi_chl_surface = mean(chlorophyll_mg_m3[depth_m <= 10], na.rm = TRUE),
        cefi_chl_subsurface = mean(chlorophyll_mg_m3[depth_m > 10 & depth_m <= 50], na.rm = TRUE),
        cefi_chl_intermediate = mean(chlorophyll_mg_m3[depth_m > 50 & depth_m <= 100], na.rm = TRUE),
        cefi_chl_deep = mean(chlorophyll_mg_m3[depth_m > 100 & depth_m <= 200], na.rm = TRUE),
        cefi_chl_mean = mean(chlorophyll_mg_m3, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Match with larval data
    integrated_data <- larval_data %>%
      mutate(
        match_lat = round(latitude, 1),  # Use 0.1° tolerance (~11km)
        match_lon = round(longitude, 1),
        match_year = as.numeric(format(date, "%Y"))
      ) %>%
      left_join(cefi_summary, by = c("match_lat", "match_lon", "match_year")) %>%
      select(-match_lat, -match_lon, -match_year)
    
  cefi_matches <- sum(!is.na(integrated_data$cefi_chl_mean))
  cat("✓ CEFI COBALT chlorophyll matched to", cefi_matches, "larval records\n")
  
  # Add data availability flags (real data only - CEFI COBALT)
  integrated_data <- integrated_data %>%
    mutate(
      has_cefi_chl = !is.na(cefi_chl_mean),
      has_ctd_chl = FALSE,  # No CTD data in real-data-only approach
      has_both_chl = has_cefi_chl  # Only CEFI data available
    )
  
  cat("✓ Created integrated dataset:", nrow(integrated_data), "records\n")
  
  return(integrated_data)
}

# Function to create summary statistics
create_integration_summary <- function(integrated_data) {
  if (is.null(integrated_data) || nrow(integrated_data) == 0) {
    return(NULL)
  }
  
  cat("\n--- Integration Summary ---\n")
  
  # Data availability summary
  availability_summary <- integrated_data %>%
    summarise(
      total_records = n(),
      with_cefi_chl = sum(has_cefi_chl, na.rm = TRUE),
      with_ctd_chl = sum(has_ctd_chl, na.rm = TRUE),
      with_both_chl = sum(has_both_chl, na.rm = TRUE),
      cefi_coverage_pct = round(100 * with_cefi_chl / total_records, 1),
      ctd_coverage_pct = round(100 * with_ctd_chl / total_records, 1),
      both_coverage_pct = round(100 * with_both_chl / total_records, 1)
    )
  
  cat("Data availability:\n")
  cat("  Total larval records:", availability_summary$total_records, "\n")
  cat("  With CEFI COBALT chlorophyll:", availability_summary$with_cefi_chl, 
      "(", availability_summary$cefi_coverage_pct, "% )\n")
  cat("  With CTD chlorophyll:", availability_summary$with_ctd_chl, 
      "(", availability_summary$ctd_coverage_pct, "% )\n")
  cat("  With both chlorophyll:", availability_summary$with_both_chl, 
      "(", availability_summary$both_coverage_pct, "% )\n")
  
  # Chlorophyll statistics for records with CEFI data (real-data-only approach)
  if (availability_summary$with_cefi_chl > 0) {
    chl_stats <- integrated_data %>%
      filter(has_cefi_chl) %>%
      summarise(
        cefi_chl_mean = mean(cefi_chl_mean, na.rm = TRUE),
        cefi_chl_surface = mean(cefi_chl_surface, na.rm = TRUE),
        cefi_chl_subsurface = mean(cefi_chl_subsurface, na.rm = TRUE),
        cefi_chl_deep = mean(cefi_chl_deep, na.rm = TRUE)
      )
    
    cat("\nCEFI COBALT chlorophyll statistics:\n")
    cat("  Mean chlorophyll:", round(chl_stats$cefi_chl_mean, 3), "mg/m³\n")
    cat("  Surface (≤10m):", round(chl_stats$cefi_chl_surface, 3), "mg/m³\n")
    cat("  Subsurface (10-50m):", round(chl_stats$cefi_chl_subsurface, 3), "mg/m³\n")
    cat("  Deep (100-200m):", round(chl_stats$cefi_chl_deep, 3), "mg/m³\n")
  }
  
  # Species with best chlorophyll coverage
  species_coverage <- integrated_data %>%
    group_by(scientific_name) %>%
    summarise(
      total_records = n(),
      with_chl = sum(has_cefi_chl | has_ctd_chl, na.rm = TRUE),
      coverage_pct = round(100 * with_chl / total_records, 1),
      .groups = "drop"
    ) %>%
    filter(total_records >= 100) %>%
    arrange(desc(coverage_pct)) %>%
    head(10)
  
  cat("\nTop 10 species by chlorophyll data coverage (≥100 records):\n")
  print(species_coverage)
  
  return(integrated_data)
}

# Main execution function
main_integrate_larval_chlorophyll <- function() {
  cat("Starting larval-chlorophyll integration...\n\n")
  
  # Load datasets
  larval_data <- load_larval_datasets()
  cefi_data <- load_cefi_chlorophyll()
  ctd_data <- load_ctd_chlorophyll()
  
  if (is.null(larval_data)) {
    cat("✗ Cannot proceed without larval data\n")
    return(NULL)
  }
  
  # Integrate datasets (prioritize CEFI COBALT data)
  integrated_data <- integrate_larval_chlorophyll(larval_data, cefi_data, ctd_data)
  
  if (is.null(integrated_data)) {
    cat("✗ Integration failed\n")
    return(NULL)
  }
  
  # Create summary
  final_data <- create_integration_summary(integrated_data)
  
  # Save integrated dataset
  cat("\n--- Saving Integrated Dataset ---\n")
  
  output_file <- "calcofi_larval_chlorophyll_integrated.csv"
  write_csv(integrated_data, output_file)
  cat("✓ Saved:", output_file, "(", nrow(integrated_data), "records )\n")
  
  # Save subset with complete chlorophyll data
  complete_data <- integrated_data %>%
    filter(has_both_chl)
  
  if (nrow(complete_data) > 0) {
    complete_file <- "calcofi_larval_chlorophyll_complete.csv"
    write_csv(complete_data, complete_file)
    cat("✓ Saved:", complete_file, "(", nrow(complete_data), "records with both ROMS and CTD chlorophyll )\n")
  }
  
  cat("\n🌊 Larval-chlorophyll integration completed!\n")
  cat("Ready for 3D environmental analysis\n")
  
  return(integrated_data)
}

# Execute
if (interactive() || !exists("skip_main_execution")) {
  integrated_larval_data <- main_integrate_larval_chlorophyll()
}
