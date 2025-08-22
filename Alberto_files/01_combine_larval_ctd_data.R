# Combine CalCOFI Larval Data with CTD Casts
# Creates combined dataset matching larval counts/stages with CTD cast depths
# Follows real-data-only rule - no synthetic data generation

library(dplyr)
library(readr)
library(lubridate)

cat("=== CalCOFI Larval-CTD Data Combination ===\n")

# Function to load real larval CSV data
load_larval_csv_data <- function() {
  cat("Loading real larval CSV data...\n")
  
  # Check for the standardized larval datasets created by create_larval_datasets.R
  larval_files <- c("Larvae.csv", "LarvaeStages.csv")
  
  larval_datasets <- list()
  
  for (file_path in larval_files) {
    if (file.exists(file_path)) {
      cat("Loading:", file_path, "\n")
      
      tryCatch({
        data <- read_csv(file_path, show_col_types = FALSE)
        file_name <- tools::file_path_sans_ext(basename(file_path))
        larval_datasets[[file_name]] <- data
        cat("✓ Loaded", nrow(data), "records from", file_name, "\n")
        
        # Show key columns for real larval data
        key_cols <- names(data)[names(data) %in% c("cruise", "latitude", "longitude", "time", "scientific_name", "larvae_count", "larvae_stage", "year")]
        if (length(key_cols) > 0) {
          cat("  Key columns:", paste(key_cols, collapse = ", "), "\n")
        }
        
        # Show temporal coverage
        if ("year" %in% names(data)) {
          year_range <- range(data$year, na.rm = TRUE)
          cat("  Temporal coverage:", year_range[1], "-", year_range[2], "\n")
        }
        
      }, error = function(e) {
        cat("Error loading", file_path, ":", e$message, "\n")
      })
    }
  }
  
  if (length(larval_datasets) == 0) {
    cat("✗ No larval CSV files found. Please run create_larval_datasets.R first\n")
    return(NULL)
  }
  
  return(larval_datasets)
}

# Function to filter larval data (exclude eggs, keep only larvae with development stages)
filter_larval_stages <- function(larval_data) {
  if (is.null(larval_data) || length(larval_data) == 0) return(NULL)
  
  cat("Filtering larval data (excluding eggs, keeping larvae with stages)...\n")
  
  filtered_data <- list()
  
  for (dataset_name in names(larval_data)) {
    data <- larval_data[[dataset_name]]
    original_count <- nrow(data)
    
    # Filter out egg stages if stage column exists
    stage_cols <- names(data)[grepl("stage|develop|phase", names(data), ignore.case = TRUE)]
    
    if (length(stage_cols) > 0) {
      cat("Found stage columns in", dataset_name, ":", paste(stage_cols, collapse = ", "), "\n")
      
      for (stage_col in stage_cols) {
        if (is.character(data[[stage_col]]) || is.factor(data[[stage_col]])) {
          # Keep only larval stages, exclude eggs
          data <- data %>%
            filter(!grepl("egg|ova", !!sym(stage_col), ignore.case = TRUE)) %>%
            filter(grepl("larv|juv|post|pre|flex", !!sym(stage_col), ignore.case = TRUE) | 
                   !is.na(!!sym(stage_col)))
        }
      }
    }
    
    # Filter by scientific names (exclude egg-specific entries)
    if ("scientific_name" %in% names(data)) {
      data <- data %>%
        filter(!grepl("egg|ova", scientific_name, ignore.case = TRUE))
    }
    
    # Keep only records with actual larval counts > 0
    count_cols <- names(data)[grepl("count|larvae_count|larval_count", names(data), ignore.case = TRUE)]
    if (length(count_cols) > 0) {
      for (count_col in count_cols) {
        data <- data %>%
          filter(!!sym(count_col) > 0 | is.na(!!sym(count_col)))
      }
    }
    
    filtered_count <- nrow(data)
    cat("✓", dataset_name, ":", original_count, "→", filtered_count, "records\n")
    
    if (filtered_count > 0) {
      filtered_data[[dataset_name]] <- data
    }
  }
  
  return(filtered_data)
}

# Function to extract tow depth information
extract_tow_depths <- function(larval_data) {
  cat("Extracting tow depth information...\n")
  
  for (dataset_name in names(larval_data)) {
    data <- larval_data[[dataset_name]]
    
    # Look for depth-related columns
    depth_cols <- names(data)[grepl("depth|tow|net", names(data), ignore.case = TRUE)]
    
    if (length(depth_cols) > 0) {
      cat("Found depth columns in", dataset_name, ":", paste(depth_cols, collapse = ", "), "\n")
      
      # Show depth range if numeric
      for (depth_col in depth_cols) {
        if (is.numeric(data[[depth_col]])) {
          depth_range <- range(data[[depth_col]], na.rm = TRUE)
          cat("  ", depth_col, "range:", depth_range[1], "-", depth_range[2], "\n")
        }
      }
    }
  }
  
  return(larval_data)
}

# Function to match larval data with CTD casts by cruise and location
match_larval_with_ctd <- function(larval_data, cast_data) {
  if (is.null(larval_data) || is.null(cast_data)) return(NULL)
  
  cat("Matching larval data with CTD casts...\n")
  
  # Combine all larval datasets
  all_larval <- bind_rows(larval_data, .id = "larval_source")
  cat("Combined larval data:", nrow(all_larval), "records\n")
  
  # Prepare cast data for matching
  cast_summary <- cast_data %>%
    select(Cruise, Sta_ID, Date, Year, Month, Lat_Dec, Lon_Dec, Bottom_D, Time) %>%
    mutate(
      cruise_id = as.character(Cruise),
      cast_date = mdy(Date),  # Parse MM/DD/YYYY format
      cast_lat = round(Lat_Dec, 3),  # 3 decimal places for better matching
      cast_lon = round(Lon_Dec, 3)
    ) %>%
    select(cruise_id, cast_lat, cast_lon, cast_date, Sta_ID, Date, Year, Month, Bottom_D, Time) %>%
    distinct()
  
  cat("CTD cast data prepared:", nrow(cast_summary), "unique casts\n")
  
  # Prepare larval data for matching
  if (all(c("cruise", "latitude", "longitude") %in% names(all_larval))) {
    larval_for_matching <- all_larval %>%
      mutate(
        cruise_id = as.character(cruise),
        larval_lat = round(latitude, 3),
        larval_lon = round(longitude, 3),
        larval_date = as.Date(time)
      ) %>%
      filter(!is.na(cruise_id), !is.na(larval_lat), !is.na(larval_lon))
    
    cat("Larval data prepared for matching:", nrow(larval_for_matching), "records\n")
    
    # Match by cruise and location
    matched_data <- larval_for_matching %>%
      left_join(cast_summary, 
                by = c("cruise_id", "larval_lat" = "cast_lat", "larval_lon" = "cast_lon"),
                relationship = "many-to-many") %>%
      filter(!is.na(Sta_ID))  # Keep only successfully matched records
    
    cat("✓ Successfully matched", nrow(matched_data), "larval records with CTD casts\n")
    
    if (nrow(matched_data) > 0) {
      # Add matching quality indicators
      matched_data <- matched_data %>%
        mutate(
          location_match = "exact",
          date_diff_days = case_when(
            !is.na(larval_date) & !is.na(cast_date) ~ as.numeric(abs(larval_date - cast_date)),
            TRUE ~ NA_real_
          )
        )
      
      return(matched_data)
    }
  }
  
  # If exact matching fails, try broader matching
  cat("Attempting broader geographic matching...\n")
  
  if (all(c("cruise", "latitude", "longitude") %in% names(all_larval))) {
    # Broader matching with 0.1 degree tolerance
    larval_broad <- all_larval %>%
      mutate(
        cruise_id = as.character(cruise),
        larval_lat = round(latitude, 1),
        larval_lon = round(longitude, 1)
      )
    
    cast_broad <- cast_data %>%
      mutate(
        cruise_id = as.character(Cruise),
        cast_lat = round(Lat_Dec, 1),
        cast_lon = round(Lon_Dec, 1)
      ) %>%
      select(cruise_id, cast_lat, cast_lon, Sta_ID, Date, Bottom_D) %>%
      distinct()
    
    matched_broad <- larval_broad %>%
      left_join(cast_broad, 
                by = c("cruise_id", "larval_lat" = "cast_lat", "larval_lon" = "cast_lon")) %>%
      filter(!is.na(Sta_ID))
    
    cat("✓ Broader matching found", nrow(matched_broad), "matches\n")
    return(matched_broad)
  }
  
  cat("No successful matches found\n")
  return(all_larval)
}

# Main execution function
main_larval_ctd_combination <- function() {
  cat("Starting CalCOFI larval-CTD data combination...\n\n")
  
  # Load CTD cast data (use historical data if available)
  cast_file <- "calcofi_194903-202105_cast.csv"
  if (!file.exists(cast_file)) {
    cat("⚠️  Historical cast data not found, trying recent data\n")
    cast_file <- "calcofi_casts_recent.csv"
    if (!file.exists(cast_file)) {
      cat("✗ No CTD cast data found. Please run 00_calcofi_full_historical_download.R first\n")
      return(NULL)
    }
  }
  
  cast_data <- read_csv(cast_file, show_col_types = FALSE)
  cat("✓ Loaded CTD cast data:", nrow(cast_data), "records\n")
  cat("  Date range:", min(cast_data$Date), "to", max(cast_data$Date), "\n")
  cat("  Unique cruises:", length(unique(cast_data$Cruise)), "\n")
  
  # Load larval CSV data
  larval_data <- load_larval_csv_data()
  
  if (is.null(larval_data)) {
    cat("✗ No larval data available for processing\n")
    return(NULL)
  }
  
  # Filter larval data (exclude eggs, keep larvae with stages)
  larval_filtered <- filter_larval_stages(larval_data)
  
  if (is.null(larval_filtered) || length(larval_filtered) == 0) {
    cat("✗ No larval data remaining after filtering\n")
    return(NULL)
  }
  
  # Extract tow depth information
  larval_with_depths <- extract_tow_depths(larval_filtered)
  
  # Match larval data with CTD casts
  matched_data <- match_larval_with_ctd(larval_with_depths, cast_data)
  
  # Save results
  if (!is.null(matched_data) && nrow(matched_data) > 0) {
    output_file <- "calcofi_larval_ctd_combined.csv"
    write_csv(matched_data, output_file)
    cat("✓ Saved combined dataset:", output_file, "\n")
    
    # Create summary
    cat("\n=== Combined Dataset Summary ===\n")
    cat("Total records:", nrow(matched_data), "\n")
    
    if ("scientific_name" %in% names(matched_data)) {
      species_count <- length(unique(matched_data$scientific_name))
      cat("Unique species:", species_count, "\n")
      
      # Top species
      top_species <- matched_data %>%
        count(scientific_name, sort = TRUE) %>%
        head(5)
      cat("Top 5 species:\n")
      print(top_species)
    }
    
    if ("larval_source" %in% names(matched_data)) {
      source_summary <- matched_data %>%
        count(larval_source, sort = TRUE)
      cat("Records by source:\n")
      print(source_summary)
    }
    
    if ("Bottom_D" %in% names(matched_data)) {
      depth_summary <- matched_data %>%
        summarise(
          min_depth = min(Bottom_D, na.rm = TRUE),
          max_depth = max(Bottom_D, na.rm = TRUE),
          mean_depth = mean(Bottom_D, na.rm = TRUE)
        )
      cat("Bottom depth range:", depth_summary$min_depth, "-", depth_summary$max_depth, "m\n")
    }
    
    return(matched_data)
  }
  
  cat("✗ No data to save after processing\n")
  return(NULL)
}

# Execute
if (interactive() || !exists("skip_main_execution")) {
  combined_data <- main_larval_ctd_combination()
  cat("\n🐟 CalCOFI larval-CTD combination completed!\n")
}
