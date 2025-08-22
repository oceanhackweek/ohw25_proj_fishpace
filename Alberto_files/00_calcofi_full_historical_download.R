# CalCOFI Full Historical Data Download (1990-Present)
# Downloads complete CalCOFI database to match full larval dataset temporal range

library(dplyr)
library(readr)
library(httr)
library(utils)
library(lubridate)

cat("=== CalCOFI Full Historical Data Download ===\n")

# CalCOFI official download URLs
calcofi_urls <- list(
  # Complete historical database (1949-2021)
  database_csv = "https://calcofi.org/downloads/database/CalCOFI_Database_194903-202105_csv_16October2023.zip",
  
  # Most recent master database 
  master_db = "https://calcofi.org/downloads/database/CalCOFI_4903-2311_Master.accdb"
  
)

# Function to download and extract CalCOFI data
download_calcofi_data <- function(url, dest_dir = "calcofi_downloads") {
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }
  
  filename <- basename(url)
  dest_file <- file.path(dest_dir, filename)
  
  cat("Downloading:", filename, "\n")
  cat("URL:", url, "\n")
  
  tryCatch({
    response <- GET(url, write_disk(dest_file, overwrite = TRUE), progress())
    
    if (status_code(response) == 200) {
      cat("✓ Downloaded:", filename, "(", round(file.size(dest_file) / 1024 / 1024, 1), "MB )\n")
      
      # Extract if it's a zip file
      if (grepl("\\.zip$", filename)) {
        extract_dir <- file.path(dest_dir, gsub("\\.zip$", "", filename))
        if (!dir.exists(extract_dir)) {
          dir.create(extract_dir, recursive = TRUE)
        }
        
        cat("Extracting to:", extract_dir, "\n")
        unzip(dest_file, exdir = extract_dir)
        cat("✓ Extracted:", filename, "\n")
        
        return(extract_dir)
      }
      
      return(dest_file)
    } else {
      cat("✗ Download failed with status:", status_code(response), "\n")
      return(NULL)
    }
  }, error = function(e) {
    cat("✗ Download error:", e$message, "\n")
    return(NULL)
  })
}

# Function to load CSV datasets from extracted files
load_calcofi_datasets <- function(extract_dir) {
  if (!dir.exists(extract_dir)) {
    cat("✗ Extract directory not found:", extract_dir, "\n")
    return(NULL)
  }
  
  # Find CSV files
  csv_files <- list.files(extract_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  
  if (length(csv_files) == 0) {
    cat("✗ No CSV files found in:", extract_dir, "\n")
    return(NULL)
  }
  
  cat("Found", length(csv_files), "CSV files\n")
  
  datasets <- list()
  
  for (csv_file in csv_files) {
    file_name <- tools::file_path_sans_ext(basename(csv_file))
    cat("Loading:", file_name, "\n")
    
    tryCatch({
      # Try different encodings for CalCOFI data
      data <- read_csv(csv_file, locale = locale(encoding = "latin1"), show_col_types = FALSE)
      
      if (nrow(data) > 0) {
        datasets[[file_name]] <- data
        cat("✓ Loaded", file_name, ":", nrow(data), "records\n")
      }
    }, error = function(e) {
      cat("Error loading", basename(csv_file), ":", e$message, "\n")
    })
  }
  
  return(datasets)
}

# Function to filter data for larval analysis period (1990-present)
filter_larval_period <- function(datasets, start_year = 1990, end_year = 2024) {
  if (is.null(datasets)) return(NULL)
  
  cat("Filtering data for larval analysis period (", start_year, "-", end_year, ")...\n")
  filtered_data <- list()
  
  for (name in names(datasets)) {
    data <- datasets[[name]]
    
    # Try to find date/time columns
    date_cols <- names(data)[grepl("date|time|year", names(data), ignore.case = TRUE)]
    
    if (length(date_cols) > 0) {
      cat("Filtering", name, "by", date_cols[1], "\n")
      
      # Try different date parsing approaches
      if ("Year" %in% names(data)) {
        # Direct year column
        filtered <- data %>% filter(Year >= start_year & Year <= end_year)
      } else if (any(grepl("date", names(data), ignore.case = TRUE))) {
        # Date column - try to parse
        date_col <- names(data)[grepl("date", names(data), ignore.case = TRUE)][1]
        
        tryCatch({
          data_with_year <- data %>%
            mutate(parsed_year = year(as.Date(!!sym(date_col))))
          
          filtered <- data_with_year %>%
            filter(parsed_year >= start_year & parsed_year <= end_year) %>%
            select(-parsed_year)
        }, error = function(e) {
          cat("Date parsing failed for", name, "- keeping all data\n")
          filtered <- data
        })
      } else {
        # No clear date column - keep all data
        cat("No clear date column in", name, "- keeping all data\n")
        filtered <- data
      }
      
      filtered_data[[name]] <- filtered
      cat("✓", name, ":", nrow(filtered), "records after filtering\n")
    } else {
      # No date columns found - keep all data
      filtered_data[[name]] <- data
      cat("✓", name, ":", nrow(data), "records (no date filtering)\n")
    }
  }
  
  return(filtered_data)
}

# Function to save datasets as CSV files
save_datasets <- function(datasets, prefix = "calcofi") {
  if (is.null(datasets)) return(NULL)
  
  saved_files <- c()
  
  for (name in names(datasets)) {
    data <- datasets[[name]]
    filename <- paste0(prefix, "_", tolower(name), ".csv")
    
    write_csv(data, filename)
    cat("✓ Saved:", filename, "(", nrow(data), "records )\n")
    saved_files <- c(saved_files, filename)
  }
  
  return(saved_files)
}

# Main execution function
main_full_download <- function() {
  cat("Starting CalCOFI full historical data download...\n")
  
  # Download main database
  extract_dir <- download_calcofi_data(calcofi_urls$database_csv)
  
  if (is.null(extract_dir)) {
    cat("Failed to download main database\n")
    return(NULL)
  }
  
  # Load datasets
  datasets <- load_calcofi_datasets(extract_dir)
  
  if (is.null(datasets)) {
    cat("Failed to load datasets\n")
    return(NULL)
  }
  
  # Filter for larval analysis period (1990-2024)
  filtered_data <- filter_larval_period(datasets)
  
  # Save filtered datasets
  saved_files <- save_datasets(filtered_data)
  
  # Summary
  cat("\n=== Download Summary ===\n")
  cat("Main database files saved:\n")
  for (file in saved_files) {
    cat("•", file, "\n")
  }

  
  cat("\n📊 Full historical CalCOFI download completed!\n")
  cat("Data range: 1990-2024 (matches larval dataset temporal coverage)\n")
  
  return(list(main_files = saved_files))
}

# Execute
if (interactive() || !exists("skip_main_execution")) {
  full_data <- main_full_download()
}
