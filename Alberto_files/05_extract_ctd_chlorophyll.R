# Extract CTD Chlorophyll-a and Fluorescence from CalCOFI Bottle Data
# Identifies and extracts chlorophyll measurements from CTD casts
# Compares with ROMS model estimates and calculates differences

library(dplyr)
library(readr)
library(lubridate)

cat("=== CTD Chlorophyll-a Extraction ===\n")

# Function to examine CTD bottle data structure
examine_ctd_data_structure <- function(bottle_file = "calcofi_194903-202105_bottle.csv") {
  cat("Examining CTD bottle data structure...\n")
  
  # Read just the header to identify chlorophyll-related columns
  tryCatch({
    # Read first few rows to check structure
    sample_data <- read_csv(bottle_file, n_max = 10, locale = locale(encoding = "latin1"))
    
    cat("✓ Successfully read bottle data sample\n")
    cat("Total columns:", ncol(sample_data), "\n")
    
    # Find chlorophyll-related columns
    chl_columns <- names(sample_data)[grepl("chlor|chl|fluor|phae", names(sample_data), ignore.case = TRUE)]
    
    cat("Chlorophyll-related columns found:\n")
    for (col in chl_columns) {
      cat("•", col, "\n")
    }
    
    # Check for actual data in these columns
    if (length(chl_columns) > 0) {
      cat("\nSample values from chlorophyll columns:\n")
      for (col in chl_columns) {
        non_na_values <- sample_data[[col]][!is.na(sample_data[[col]])]
        if (length(non_na_values) > 0) {
          cat("", col, ":", paste(head(non_na_values, 3), collapse = ", "), "\n")
        } else {
          cat("", col, ": All NA in sample\n")
        }
      }
    }
    
    return(list(columns = chl_columns, sample_data = sample_data))
    
  }, error = function(e) {
    cat("✗ Error reading bottle data:", e$message, "\n")
    return(NULL)
  })
}

# Function to extract CTD chlorophyll data
extract_ctd_chlorophyll <- function(bottle_file = "calcofi_194903-202105_bottle.csv") {
  cat("\n--- Extracting CTD Chlorophyll Data ---\n")
  
  # Read the full dataset with proper encoding
  tryCatch({
    ctd_data <- read_csv(bottle_file, locale = locale(encoding = "latin1"), show_col_types = FALSE)
    cat("✓ Loaded", nrow(ctd_data), "CTD bottle records\n")
    
    # Check for chlorophyll columns
    chl_columns <- names(ctd_data)[grepl("chlor|chl|fluor|phae", names(ctd_data), ignore.case = TRUE)]
    
    if (length(chl_columns) == 0) {
      cat("⚠️  No chlorophyll columns found in CTD data\n")
      return(NULL)
    }
    
    # Extract relevant columns for chlorophyll analysis
    ctd_chl <- ctd_data %>%
      select(
        Sta_ID, Depthm, T_degC, Salnty,
        any_of(c("ChlorA", "Chlqua", "Phaeop", "Phaqua")),
        everything()
      ) %>%
      filter(!is.na(Depthm)) %>%
      # Parse station ID to get coordinates (if available)
      mutate(
        station_line = as.numeric(substr(Sta_ID, 1, 3)),
        station_number = as.numeric(substr(Sta_ID, 6, 8))
      )
    
    # Check data availability
    if ("ChlorA" %in% names(ctd_chl)) {
      non_na_chl <- sum(!is.na(ctd_chl$ChlorA))
      cat("ChlorA column found:", non_na_chl, "non-NA values out of", nrow(ctd_chl), "records\n")
      
      if (non_na_chl > 0) {
        chl_range <- range(ctd_chl$ChlorA, na.rm = TRUE)
        cat("ChlorA range:", round(chl_range[1], 3), "to", round(chl_range[2], 3), "\n")
      }
    }
    
    if ("Phaeop" %in% names(ctd_chl)) {
      non_na_phae <- sum(!is.na(ctd_chl$Phaeop))
      cat("Phaeop (phaeopigments) column found:", non_na_phae, "non-NA values\n")
    }
    
    return(ctd_chl)
    
  }, error = function(e) {
    cat("✗ Error extracting CTD chlorophyll:", e$message, "\n")
    return(NULL)
  })
}

# Function to match CTD data with larval sampling locations
match_ctd_with_larval_locations <- function(ctd_chl, larval_file = "Larvae.csv") {
  cat("\n--- Matching CTD with Larval Locations ---\n")
  
  if (is.null(ctd_chl)) {
    cat("✗ No CTD chlorophyll data available\n")
    return(NULL)
  }
  
  # Load larval data
  larval_data <- read_csv(larval_file, show_col_types = FALSE)
  
  # Match by station ID (exact match)
  matched_ctd <- larval_data %>%
    select(larval_source, cruise, latitude, longitude, station, 
           scientific_name, larvae_count, larvae_100m3) %>%
    left_join(
      ctd_chl %>% select(Sta_ID, Depthm, T_degC, Salnty, ChlorA, Chlqua, Phaeop, Phaqua),
      by = c("station" = "Sta_ID"),
      relationship = "many-to-many"
    ) %>%
    filter(!is.na(Depthm)) %>%
    rename(
      ctd_depth = Depthm,
      ctd_temp = T_degC,
      ctd_salinity = Salnty,
      ctd_chlorophyll = ChlorA,
      ctd_chl_quality = Chlqua,
      ctd_phaeopigments = Phaeop,
      ctd_phae_quality = Phaqua
    )
  
  cat("✓ Matched", nrow(matched_ctd), "larval-CTD records\n")
  
  # Summary of CTD chlorophyll data availability
  if ("ctd_chlorophyll" %in% names(matched_ctd)) {
    chl_available <- sum(!is.na(matched_ctd$ctd_chlorophyll))
    cat("CTD chlorophyll available for", chl_available, "records\n")
    
    if (chl_available > 0) {
      chl_summary <- matched_ctd %>%
        filter(!is.na(ctd_chlorophyll)) %>%
        summarise(
          min_chl = min(ctd_chlorophyll, na.rm = TRUE),
          max_chl = max(ctd_chlorophyll, na.rm = TRUE),
          mean_chl = mean(ctd_chlorophyll, na.rm = TRUE),
          n_depths = n_distinct(ctd_depth),
          depth_range = paste(min(ctd_depth, na.rm = TRUE), "-", max(ctd_depth, na.rm = TRUE), "m")
        )
      
      cat("CTD Chlorophyll summary:\n")
      cat("  Range:", round(chl_summary$min_chl, 3), "to", round(chl_summary$max_chl, 3), "\n")
      cat("  Mean:", round(chl_summary$mean_chl, 3), "\n")
      cat("  Depth range:", chl_summary$depth_range, "\n")
      cat("  Unique depths:", chl_summary$n_depths, "\n")
    }
  }
  
  return(matched_ctd)
}

# Function to combine CTD and ROMS chlorophyll data
combine_ctd_roms_chlorophyll <- function(matched_ctd, roms_file = "calcofi_larval_chlorophyll_3d.csv") {
  cat("\n--- Combining CTD and ROMS Chlorophyll Data ---\n")
  
  if (is.null(matched_ctd)) {
    cat("✗ No matched CTD data available\n")
    return(NULL)
  }
  
  if (!file.exists(roms_file)) {
    cat("✗ ROMS chlorophyll file not found:", roms_file, "\n")
    return(NULL)
  }
  
  # Load ROMS data
  roms_data <- read_csv(roms_file, show_col_types = FALSE)
  
  # Match CTD and ROMS data by location and approximate depth
  # Use a depth tolerance for matching
  depth_tolerance <- 10  # meters
  
  combined_data <- matched_ctd %>%
    left_join(
      roms_data %>% 
        select(latitude, longitude, depth, chlorophyll_mg_m3) %>%
        rename(roms_depth = depth, roms_chlorophyll = chlorophyll_mg_m3),
      by = c("latitude", "longitude"),
      relationship = "many-to-many"
    ) %>%
    # Filter for similar depths (within tolerance)
    filter(abs(ctd_depth - roms_depth) <= depth_tolerance) %>%
    # Calculate differences between CTD and ROMS
    mutate(
      # Check if both values are available
      both_available = !is.na(ctd_chlorophyll) & !is.na(roms_chlorophyll),
      
      # Calculate absolute difference
      chl_difference = case_when(
        both_available ~ ctd_chlorophyll - roms_chlorophyll,
        TRUE ~ NA_real_
      ),
      
      # Calculate relative difference (%)
      chl_relative_diff = case_when(
        both_available & roms_chlorophyll != 0 ~ 
          (ctd_chlorophyll - roms_chlorophyll) / roms_chlorophyll * 100,
        TRUE ~ NA_real_
      ),
      
      # Depth matching quality
      depth_diff = abs(ctd_depth - roms_depth),
      depth_match_quality = case_when(
        depth_diff <= 2 ~ "excellent",
        depth_diff <= 5 ~ "good", 
        depth_diff <= 10 ~ "fair",
        TRUE ~ "poor"
      )
    ) %>%
    arrange(cruise, latitude, longitude, ctd_depth)
  
  cat("✓ Combined CTD and ROMS data:", nrow(combined_data), "records\n")
  
  # Summary of comparisons
  comparison_summary <- combined_data %>%
    filter(both_available) %>%
    summarise(
      n_comparisons = n(),
      mean_ctd_chl = mean(ctd_chlorophyll, na.rm = TRUE),
      mean_roms_chl = mean(roms_chlorophyll, na.rm = TRUE),
      mean_abs_diff = mean(abs(chl_difference), na.rm = TRUE),
      mean_rel_diff = mean(abs(chl_relative_diff), na.rm = TRUE),
      correlation = cor(ctd_chlorophyll, roms_chlorophyll, use = "complete.obs")
    )
  
  if (nrow(combined_data %>% filter(both_available)) > 0) {
    cat("\nCTD vs ROMS Chlorophyll Comparison:\n")
    cat("  Available comparisons:", comparison_summary$n_comparisons, "\n")
    cat("  Mean CTD Chl-a:", round(comparison_summary$mean_ctd_chl, 3), "\n")
    cat("  Mean ROMS Chl-a:", round(comparison_summary$mean_roms_chl, 3), "\n")
    cat("  Mean absolute difference:", round(comparison_summary$mean_abs_diff, 3), "\n")
    cat("  Mean relative difference:", round(comparison_summary$mean_rel_diff, 1), "%\n")
    if (!is.na(comparison_summary$correlation)) {
      cat("  Correlation:", round(comparison_summary$correlation, 3), "\n")
    }
  } else {
    cat("⚠️  No overlapping CTD and ROMS chlorophyll data found\n")
  }
  
  return(combined_data)
}

# Main execution function
main_ctd_chlorophyll_extraction <- function() {
  cat("Starting CTD chlorophyll-a extraction and comparison...\n\n")
  
  # Examine data structure
  structure_info <- examine_ctd_data_structure()
  
  # Extract CTD chlorophyll data
  ctd_chl <- extract_ctd_chlorophyll()
  
  # Match with larval locations
  matched_ctd <- match_ctd_with_larval_locations(ctd_chl)
  
  # Combine with ROMS data
  combined_data <- combine_ctd_roms_chlorophyll(matched_ctd)
  
  if (!is.null(combined_data)) {
    # Save combined dataset
    output_file <- "calcofi_ctd_roms_chlorophyll_combined.csv"
    write_csv(combined_data, output_file)
    cat("✓ Saved combined CTD-ROMS chlorophyll data:", output_file, "\n")
    
    # Create summary by depth zones
    depth_zone_summary <- combined_data %>%
      mutate(
        depth_zone = case_when(
          ctd_depth <= 10 ~ "Surface (0-10m)",
          ctd_depth <= 50 ~ "Subsurface (10-50m)",
          ctd_depth <= 100 ~ "Intermediate (50-100m)",
          TRUE ~ "Deep (>100m)"
        )
      ) %>%
      group_by(depth_zone) %>%
      summarise(
        n_records = n(),
        n_ctd_chl = sum(!is.na(ctd_chlorophyll)),
        n_roms_chl = sum(!is.na(roms_chlorophyll)),
        n_both = sum(both_available),
        mean_ctd_chl = mean(ctd_chlorophyll, na.rm = TRUE),
        mean_roms_chl = mean(roms_chlorophyll, na.rm = TRUE),
        mean_difference = mean(chl_difference, na.rm = TRUE),
        .groups = 'drop'
      )
    
    cat("\nChlorophyll data by depth zone:\n")
    print(depth_zone_summary)
    
    summary_file <- "ctd_roms_chlorophyll_summary.csv"
    write_csv(depth_zone_summary, summary_file)
    cat("✓ Saved depth zone summary:", summary_file, "\n")
  }
  
  cat("\n--- Data Quality Notes ---\n")
  cat("• CTD ChlorA values are likely fluorescence-derived chlorophyll-a estimates\n")
  cat("• ROMS values are model-based chlorophyll-a estimates\n")
  cat("• Both should be in comparable units (mg/m³) but may have different accuracies\n")
  cat("• Large differences may indicate model limitations or measurement uncertainties\n")
  
  return(list(
    structure_info = structure_info,
    ctd_data = ctd_chl,
    matched_data = matched_ctd,
    combined_data = combined_data
  ))
}

# Execute
if (interactive() || !exists("skip_main_execution")) {
  ctd_results <- main_ctd_chlorophyll_extraction()
  cat("\n🧪 CTD chlorophyll-a extraction completed!\n")
}
