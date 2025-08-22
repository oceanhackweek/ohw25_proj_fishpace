# Debug spatial-temporal matching between CEFI and larval data
library(readr)
library(dplyr)

cat("=== Debugging CEFI-Larval Data Matching ===\n")

# Load data
larval <- read_csv('calcofi_larval_chlorophyll_integrated.csv', show_col_types=FALSE)
cefi <- read_csv('cefi_cobalt_chlorophyll_3d.csv', show_col_types=FALSE)

# Check temporal ranges
larval_dates <- larval %>% filter(!is.na(date))
cefi_dates <- as.Date(unique(cefi$time), origin='1970-01-01')

cat("Temporal Coverage:\n")
cat("  Larval:", as.character(min(larval_dates$date)), "to", as.character(max(larval_dates$date)), "\n")
cat("  CEFI:  ", as.character(min(cefi_dates)), "to", as.character(max(cefi_dates)), "\n")

# Check overlap
overlap_start <- max(min(larval_dates$date), min(cefi_dates))
overlap_end <- min(max(larval_dates$date), max(cefi_dates))
cat("  Overlap:", as.character(overlap_start), "to", as.character(overlap_end), "\n")

# Check spatial ranges
cat("\nSpatial Coverage:\n")
cat("  Larval Lon:", round(min(larval$longitude, na.rm=TRUE), 2), "to", round(max(larval$longitude, na.rm=TRUE), 2), "\n")
cat("  Larval Lat:", round(min(larval$latitude, na.rm=TRUE), 2), "to", round(max(larval$latitude, na.rm=TRUE), 2), "\n")
cat("  CEFI Lon:  ", round(min(cefi$longitude), 2), "to", round(max(cefi$longitude), 2), "\n")
cat("  CEFI Lat:  ", round(min(cefi$latitude), 2), "to", round(max(cefi$latitude), 2), "\n")

# Check for records in overlap period
overlap_larval <- larval %>% 
  filter(date >= overlap_start & date <= overlap_end)
cat("\nRecords in overlap period:\n")
cat("  Larval records:", nrow(overlap_larval), "\n")

if (nrow(overlap_larval) > 0) {
  # Test matching with sample data
  cat("\nTesting spatial matching with sample data:\n")
  
  # Create CEFI summary for overlap period
  cefi_overlap <- cefi %>%
    mutate(match_date = as.Date(time, origin = "1970-01-01")) %>%
    filter(match_date >= overlap_start & match_date <= overlap_end) %>%
    mutate(
      match_lat = round(latitude, 2),
      match_lon = round(longitude, 2)
    ) %>%
    group_by(match_lat, match_lon, match_date) %>%
    summarise(
      cefi_chl_mean = mean(chlorophyll_mg_m3, na.rm = TRUE),
      .groups = "drop"
    )
  
  cat("  CEFI summary records:", nrow(cefi_overlap), "\n")
  
  # Test join
  test_join <- overlap_larval %>%
    mutate(
      match_lat = round(latitude, 2),
      match_lon = round(longitude, 2),
      match_date = date
    ) %>%
    left_join(cefi_overlap, by = c("match_lat", "match_lon", "match_date"))
  
  matches <- sum(!is.na(test_join$cefi_chl_mean))
  cat("  Successful matches:", matches, "\n")
  
  if (matches > 0) {
    cat("  Match examples:\n")
    matched_records <- test_join %>% 
      filter(!is.na(cefi_chl_mean)) %>%
      select(match_lat, match_lon, match_date, cefi_chl_mean) %>%
      head(5)
    print(matched_records)
  } else {
    cat("  No matches found. Checking coordinate precision...\n")
    cat("  Sample larval coords (rounded):\n")
    sample_larval <- overlap_larval %>%
      mutate(
        match_lat = round(latitude, 2),
        match_lon = round(longitude, 2)
      ) %>%
      select(match_lat, match_lon, date) %>%
      head(5)
    print(sample_larval)
    
    cat("  Sample CEFI coords (rounded):\n")
    sample_cefi <- cefi_overlap %>%
      select(match_lat, match_lon, match_date) %>%
      head(5)
    print(sample_cefi)
  }
} else {
  cat("  No larval records in overlap period!\n")
}

cat("\n=== Debug Complete ===\n")
