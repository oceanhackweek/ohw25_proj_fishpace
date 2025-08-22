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
  
  # Use CEFI COBALT chlorophyll data if available
  if (!is.null(cefi_data) && nrow(cefi_data) > 0) {
    cat("Using CEFI COBALT chlorophyll data...\n")
    
    # CEFI data has columns: longitude, latitude, depth_m, time, chlorophyll_mg_m3
    # Create depth-based summaries for integration with larval data
    integrated_data <- cefi_data %>%
      mutate(
        cefi_chl_surface = ifelse(depth_m <= 10, chlorophyll_mg_m3, NA),
        cefi_chl_subsurface = ifelse(depth_m > 10 & depth_m <= 50, chlorophyll_mg_m3, NA),
        cefi_chl_intermediate = ifelse(depth_m > 50 & depth_m <= 100, chlorophyll_mg_m3, NA),
        cefi_chl_deep = ifelse(depth_m > 100, chlorophyll_mg_m3, NA),
        cefi_chl_mean = chlorophyll_mg_m3
      )
      
    cat("✓ Loaded integrated CEFI COBALT data:", nrow(integrated_data), "records\n")
    return(integrated_data)
  }
  
  # Fallback: Use existing CTD-ROMS combined data if available
  if (!is.null(ctd_data) && nrow(ctd_data) > 0) {
    cat("Fallback: Using existing CTD-ROMS chlorophyll data...\n")
    
    # The CTD data file already contains integrated larval-CTD-ROMS data
    integrated_data <- ctd_data %>%
      mutate(
        # Create depth zone summaries from existing data
        roms_chl_surface = ifelse(ctd_depth <= 10, roms_chlorophyll, NA),
        roms_chl_subsurface = ifelse(ctd_depth > 10 & ctd_depth <= 50, roms_chlorophyll, NA),
        roms_chl_deep = ifelse(ctd_depth > 50, roms_chlorophyll, NA),
        roms_chl_mean = roms_chlorophyll,
        
        ctd_chl_surface = ifelse(ctd_depth <= 10, ctd_chlorophyll, NA),
        ctd_chl_subsurface = ifelse(ctd_depth > 10 & ctd_depth <= 50, ctd_chlorophyll, NA), 
        ctd_chl_deep = ifelse(ctd_depth > 50, ctd_chlorophyll, NA),
        ctd_chl_mean = ctd_chlorophyll
      )
    
    cat("✓ Loaded integrated CTD-ROMS data:", nrow(integrated_data), "records\n")
    return(integrated_data)
  }
  
  # Fallback: Start with larval data as base and try to add CEFI chlorophyll data
  integrated_data <- larval_data
  
  # Add CEFI chlorophyll if available (raw 3D data)
  if (!is.null(cefi_data) && nrow(cefi_data) > 0 && "chlorophyll_mg_m3" %in% names(cefi_data)) {
    cat("Integrating CEFI COBALT chlorophyll data...\n")
    
    # Match by location and time (with tolerance)
    cefi_summary <- cefi_data %>%
      mutate(
        match_lat = round(latitude, 2),
        match_lon = round(longitude, 2),
        match_date = as.Date(time)
      ) %>%
      group_by(match_lat, match_lon, match_date) %>%
      summarise(
        cefi_chl_surface = mean(chlorophyll_mg_m3[depth_m <= 10], na.rm = TRUE),
        cefi_chl_subsurface = mean(chlorophyll_mg_m3[depth_m > 10 & depth_m <= 50], na.rm = TRUE),
        cefi_chl_intermediate = mean(chlorophyll_mg_m3[depth_m > 50 & depth_m <= 100], na.rm = TRUE),
        cefi_chl_deep = mean(chlorophyll_mg_m3[depth_m > 100], na.rm = TRUE),
        cefi_chl_mean = mean(chlorophyll_mg_m3, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Match with larval data
    integrated_data <- integrated_data %>%
      mutate(
        match_lat = round(latitude, 2),
        match_lon = round(longitude, 2),
        match_date = date
      ) %>%
      left_join(cefi_summary, by = c("match_lat", "match_lon", "match_date")) %>%
      select(-match_lat, -match_lon, -match_date)
    
    cefi_matches <- sum(!is.na(integrated_data$cefi_chl_mean))
    cat("✓ CEFI COBALT chlorophyll matched to", cefi_matches, "larval records\n")
  }
  
  # Add missing CEFI columns with NA if no data was joined
  if (!"cefi_chl_surface" %in% names(integrated_data)) {
    integrated_data$cefi_chl_surface <- NA_real_
    integrated_data$cefi_chl_subsurface <- NA_real_
    integrated_data$cefi_chl_intermediate <- NA_real_
    integrated_data$cefi_chl_deep <- NA_real_
    integrated_data$cefi_chl_mean <- NA_real_
  }
  
  # Add missing CTD columns with NA if no data was joined
  if (!"ctd_chl_surface" %in% names(integrated_data)) {
    integrated_data$ctd_chl_surface <- NA_real_
    integrated_data$ctd_chl_subsurface <- NA_real_
    integrated_data$ctd_chl_deep <- NA_real_
    integrated_data$ctd_chl_mean <- NA_real_
    integrated_data$ctd_fluorescence_mean <- NA_real_
  }
  
  # Calculate chlorophyll differences and ratios (CEFI vs CTD)
  integrated_data <- integrated_data %>%
    mutate(
      # Chlorophyll differences (CEFI - CTD)
      chl_diff_surface = cefi_chl_surface - ctd_chl_surface,
      chl_diff_subsurface = cefi_chl_subsurface - ctd_chl_subsurface,
      chl_diff_mean = cefi_chl_mean - ctd_chl_mean,
      
      # Chlorophyll ratios (CEFI / CTD)
      chl_ratio_surface = ifelse(!is.na(ctd_chl_surface) & ctd_chl_surface > 0, 
                                cefi_chl_surface / ctd_chl_surface, NA),
      chl_ratio_mean = ifelse(!is.na(ctd_chl_mean) & ctd_chl_mean > 0, 
                             cefi_chl_mean / ctd_chl_mean, NA),
      
      # Data availability flags
      has_cefi_chl = !is.na(cefi_chl_mean),
      has_ctd_chl = !is.na(ctd_chl_mean),
      has_both_chl = has_cefi_chl & has_ctd_chl
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
  
  # Chlorophyll statistics for records with both datasets
  if (availability_summary$with_both_chl > 0) {
    chl_stats <- integrated_data %>%
      filter(has_both_chl) %>%
      summarise(
        cefi_chl_mean = mean(cefi_chl_mean, na.rm = TRUE),
        ctd_chl_mean = mean(ctd_chl_mean, na.rm = TRUE),
        chl_diff_mean = mean(chl_diff_mean, na.rm = TRUE),
        chl_ratio_mean = mean(chl_ratio_mean, na.rm = TRUE),
        correlation = cor(cefi_chl_mean, ctd_chl_mean, use = "complete.obs")
      )
    
    cat("\nChlorophyll comparison (records with both CEFI and CTD):\n")
    cat("  CEFI COBALT chlorophyll mean:", round(chl_stats$cefi_chl_mean, 3), "mg/m³\n")
    cat("  CTD chlorophyll mean:", round(chl_stats$ctd_chl_mean, 3), "mg/m³\n")
    cat("  Mean difference (CEFI - CTD):", round(chl_stats$chl_diff_mean, 3), "mg/m³\n")
    cat("  Mean ratio (CEFI / CTD):", round(chl_stats$chl_ratio_mean, 2), "\n")
    cat("  Correlation:", round(chl_stats$correlation, 3), "\n")
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
