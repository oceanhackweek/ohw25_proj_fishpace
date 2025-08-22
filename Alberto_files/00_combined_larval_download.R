# Combined CalCOFI Larval Data Download and Processing
# Combines historical database download with ERDDAP larval data creation
# Efficient single script for all larval data needs

library(dplyr)
library(readr)
library(httr)
library(utils)
library(lubridate)

cat("=== Combined CalCOFI Larval Data Download and Processing ===\n")

# Function to download CalCOFI larval data from NOAA ERDDAP servers
download_calcofi_larval_data <- function() {
  cat("\n--- Downloading CalCOFI Larval Data (NOAA ERDDAP) ---\n")
  
  # NOAA ERDDAP CalCOFI larval fish datasets (current data)
  datasets <- list(
    larval_counts = list(
      dataset_id = "erdCalCOFIlrvcnt",
      url = "https://coastwatch.pfeg.noaa.gov/erddap/tabledap/erdCalCOFIlrvcnt.csv",
      filename = "calcofi_erdCalCOFIlrvcnt.csv",
      description = "CalCOFI Larvae Counts"
    ),
    larval_stages = list(
      dataset_id = "erdCalCOFIlrvstg", 
      url = "https://coastwatch.pfeg.noaa.gov/erddap/tabledap/erdCalCOFIlrvstg.csv",
      filename = "calcofi_erdCalCOFIlrvstg.csv",
      description = "CalCOFI Larvae Stages"
    )
  )
  
  dest_dir <- "calcofi_downloads"
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }
  
  success_count <- 0
  
  for (dataset_name in names(datasets)) {
    dataset <- datasets[[dataset_name]]
    csv_path <- file.path(dest_dir, dataset$filename)
    
    cat("Downloading:", dataset$description, "\n")
    cat("Dataset ID:", dataset$dataset_id, "\n")
    cat("URL:", dataset$url, "\n")
    
    tryCatch({
      response <- GET(dataset$url, write_disk(csv_path, overwrite = TRUE), progress(), timeout(600))
      
      if (status_code(response) == 200) {
        file_size <- file.size(csv_path) / (1024^2)  # MB
        cat("✓ Downloaded:", dataset$filename, sprintf("(%.1f MB)\n", file_size))
        
        # Copy larval stages to standardized name for processing
        if (dataset$dataset_id == "erdCalCOFIlrvstg") {
          file.copy(csv_path, "calcofi_erdCalCOFIlrvstg.csv", overwrite = TRUE)
          cat("✓ Copied to: calcofi_erdCalCOFIlrvstg.csv\n")
          
          # Check file structure
          cat("Checking file structure...\n")
          test_read <- read_csv("calcofi_erdCalCOFIlrvstg.csv", n_max = 5, show_col_types = FALSE)
          cat("✓ File has", ncol(test_read), "columns and", nrow(test_read), "sample rows\n")
          cat("Columns:", paste(names(test_read), collapse = ", "), "\n")
        }
        
        success_count <- success_count + 1
        
      } else {
        cat("✗ Download failed with status:", status_code(response), "\n")
        cat("Response headers:", headers(response), "\n")
      }
      
    }, error = function(e) {
      cat("✗ Download error:", e$message, "\n")
      cat("Check internet connection and ERDDAP server availability\n")
    })
    
    cat("\n")
  }
  
  if (success_count > 0) {
    cat("✓ Downloaded", success_count, "of", length(datasets), "ERDDAP larval datasets\n")
    return(TRUE)
  } else {
    cat("✗ No ERDDAP datasets downloaded successfully\n")
    return(FALSE)
  }
}

# Function to create standardized larval datasets
create_larval_datasets <- function() {
  # Force fresh download from ERDDAP - remove existing files
  if (file.exists("Larvae.csv")) {
    file.remove("Larvae.csv")
    cat("✓ Removed old Larvae.csv to force fresh download\n")
  }
  if (file.exists("LarvaeStages.csv")) {
    file.remove("LarvaeStages.csv")
    cat("✓ Removed old LarvaeStages.csv to force fresh download\n")
  }
  
  cat("Creating standardized larval datasets from ERDDAP data...\n")
  
  # Load larval stages dataset (most complete)
  stages_file <- "calcofi_erdCalCOFIlrvstg.csv"
  if (!file.exists(stages_file)) {
    cat("✗ Larval stages file not found:", stages_file, "\n")
    cat("⚠️  Need to download ERDDAP larval data first\n")
    cat("⚠️  Downloading now...\n")
    
    # Download CalCOFI larval data using direct download
    download_success <- download_calcofi_larval_data()
    
    # Check again
    if (!file.exists(stages_file)) {
      cat("✗ Still no larval stages file after download attempt\n")
      return(NULL)
    }
  }
  
  # Read and process larval stages data
  larval_raw <- read_csv(stages_file, show_col_types = FALSE)
  cat("✓ Loaded raw larval data:", nrow(larval_raw), "records\n")
  
  # Process and clean the data
  larval_clean <- larval_raw %>%
    # Skip the units row (row 2) and select relevant columns using actual column names
    slice(-1) %>%  # Remove units row
    select(
      cruise,
      ship, 
      ship_code,
      order_occupied,
      tow_type,
      tow_number,
      net_location,
      time,
      latitude,
      longitude,
      line,
      station,
      standard_haul_factor,
      volume_sampled,
      proportion_sorted,
      scientific_name,
      common_name,
      itis_tsn,
      calcofi_species_code,
      larvae_stage,
      larvae_stage_count,
      larvae_10m2,
      larvae_100m3
    ) %>%
    mutate(
      # Parse temporal information
      time = as.POSIXct(time, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      date = as.Date(time),
      year = year(time),
      month = month(time),
      
      # Standardize numeric columns
      larvae_count = as.numeric(larvae_stage_count),
      larvae_10m2 = as.numeric(larvae_10m2),
      larvae_100m3 = as.numeric(larvae_100m3),
      
      # Add metadata
      data_source = "CalCOFI_ERDDAP",
      record_type = "LARVAL_FISH",
      larval_source = "stages"
    ) %>%
    # Filter for historical range (1990-present)
    filter(year >= 1990) %>%
    # Remove records with missing essential data
    filter(
      !is.na(latitude), 
      !is.na(longitude), 
      !is.na(scientific_name),
      !is.na(time)
    ) %>%
    # Filter out eggs, keep larvae only
    filter(!grepl("egg|ova", scientific_name, ignore.case = TRUE)) %>%
    # Remove records with zero or negative counts
    filter(is.na(larvae_count) | larvae_count > 0)
  
  cat("✓ Processed larval data:", nrow(larval_clean), "records (1990-present, larvae only)\n")
  
  # Show data summary
  if (nrow(larval_clean) > 0) {
    year_range <- range(larval_clean$year, na.rm = TRUE)
    cat("Temporal coverage:", year_range[1], "-", year_range[2], "\n")
    
    species_count <- length(unique(larval_clean$scientific_name))
    cat("Unique species:", species_count, "\n")
    
    # Show spatial coverage
    spatial_summary <- larval_clean %>%
      summarise(
        lat_min = min(latitude, na.rm = TRUE),
        lat_max = max(latitude, na.rm = TRUE),
        lon_min = min(longitude, na.rm = TRUE),
        lon_max = max(longitude, na.rm = TRUE)
      )
    cat("Spatial coverage: Lat", spatial_summary$lat_min, "to", spatial_summary$lat_max, 
        ", Lon", spatial_summary$lon_min, "to", spatial_summary$lon_max, "\n")
  }
  
  return(larval_clean)
}

# Function to match with CTD data
match_larval_with_ctd <- function(larval_data) {
  if (is.null(larval_data) || nrow(larval_data) == 0) {
    return(NULL)
  }
  
  cat("\n--- Matching Larval Data with CTD ---\n")
  
  # Load historical CTD cast data
  cast_file <- "calcofi_194903-202105_cast.csv"
  if (!file.exists(cast_file)) {
    cat("⚠️  Using recent CTD data instead of historical\n")
    cast_file <- "calcofi_casts_recent.csv"
  }
  
  if (!file.exists(cast_file)) {
    cat("⚠️  No CTD data available for matching\n")
    return(larval_data)
  }
  
  cast_data <- read_csv(cast_file, show_col_types = FALSE)
  cat("✓ Loaded CTD cast data:", nrow(cast_data), "records\n")
  
  # Prepare data for matching
  larval_for_matching <- larval_data %>%
    mutate(
      cruise_id = as.character(cruise),
      larval_lat = as.numeric(latitude),  # Convert to numeric without rounding
      larval_lon = as.numeric(longitude),
      larval_date = date
    )
  
  cast_summary <- cast_data %>%
    mutate(
      cruise_id = as.character(Cruise),
      cast_date = mdy(Date),
      cast_lat = round(Lat_Dec, 2),
      cast_lon = round(Lon_Dec, 2),
      station_id = as.character(Sta_ID)  # Ensure consistent data type
    ) %>%
    # Filter out rows with failed date parsing
    filter(!is.na(cast_date)) %>%
    # Ensure cast_date is included in select
    select(cruise_id, cast_lat, cast_lon, cast_date, station_id, Date, Year, Month, Bottom_D, Time) %>%
    distinct() %>%
    # Remove duplicates by keeping first match per location/cruise
    group_by(cruise_id, cast_lat, cast_lon) %>%
    slice_head(n = 1) %>%
    ungroup()
  
  cat("✓ Prepared", nrow(cast_summary), "CTD cast records for matching\n")
  
  # Match by cruise and approximate location
  matched_data <- larval_for_matching %>%
    left_join(cast_summary, 
              by = c("cruise_id", "larval_lat" = "cast_lat", "larval_lon" = "cast_lon"),
              relationship = "many-to-one") %>%  # Explicit relationship to avoid warning
    mutate(
      location_match = ifelse(!is.na(station_id), "approximate", "no_match"),
      # Add safe date difference calculation with fallback
      date_diff_days = case_when(
        !is.na(larval_date) & !is.na(cast_date) ~ as.numeric(abs(larval_date - cast_date)),
        TRUE ~ NA_real_
      )
    )
  
  matched_count <- sum(!is.na(matched_data$station_id))
  cat("✓ Matched", matched_count, "of", nrow(larval_data), "larval records with CTD casts\n")
  
  return(matched_data)
}

# Function to save larval datasets
save_larval_datasets <- function(larval_data) {
  if (is.null(larval_data) || nrow(larval_data) == 0) {
    cat("No data to save\n")
    return(NULL)
  }
  
  cat("\n--- Saving Larval Datasets ---\n")
  
  # Save main larval dataset as Larvae.csv
  write_csv(larval_data, "Larvae.csv")
  cat("✓ Saved: Larvae.csv (", nrow(larval_data), "records )\n")
  
  # Create and save stages-specific dataset
  larval_stages <- larval_data %>%
    filter(!is.na(larvae_stage))
  
  if (nrow(larval_stages) > 0) {
    write_csv(larval_stages, "LarvaeStages.csv")
    cat("✓ Saved: LarvaeStages.csv (", nrow(larval_stages), "records with stage info )\n")
  }
  
  # Create summary statistics
  cat("\n--- Dataset Summary ---\n")
  
  # Temporal summary
  temporal_summary <- larval_data %>%
    group_by(year) %>%
    summarise(
      records = n(),
      species = n_distinct(scientific_name),
      .groups = "drop"
    ) %>%
    arrange(year)
  
  cat("Records by year (first 5 and last 5):\n")
  print(head(temporal_summary, 5))
  if (nrow(temporal_summary) > 10) {
    cat("...\n")
    print(tail(temporal_summary, 5))
  }
  
  # Species summary
  species_summary <- larval_data %>%
    count(scientific_name, sort = TRUE) %>%
    head(10)
  
  cat("Top 10 species by record count:\n")
  print(species_summary)
  
  # CTD matching summary
  ctd_summary <- larval_data %>%
    count(location_match, sort = TRUE)
  
  cat("CTD matching results:\n")
  print(ctd_summary)
  
  return(larval_data)
}

# Main execution function
main_combined_larval_processing <- function() {
  cat("Starting combined CalCOFI larval data download and processing...\n\n")
  
  # Download ERDDAP larval data
  download_success <- download_calcofi_larval_data()
  
  if (!download_success) {
    cat("✗ Failed to download ERDDAP larval data\n")
    return(NULL)
  }
  
  # Create standardized larval dataset
  larval_data <- create_larval_datasets()
  
  if (is.null(larval_data)) {
    cat("✗ Failed to create larval dataset\n")
    return(NULL)
  }
  
  # Match with CTD data
  larval_with_ctd <- match_larval_with_ctd(larval_data)
  
  # Save datasets
  final_data <- save_larval_datasets(larval_with_ctd)
  
  cat("\n🐟 Combined CalCOFI larval data processing completed successfully!\n")
  cat("Files created: Larvae.csv, LarvaeStages.csv\n")
  cat("Ready for 3D chlorophyll integration\n")
  
  return(final_data)
}

# Execute main function
if (interactive() || !exists("skip_main_execution")) {
  larval_data <- main_combined_larval_processing()
}
