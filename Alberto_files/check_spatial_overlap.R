# Check for spatial overlap between CEFI and larval data
library(readr)
library(dplyr)

cat("=== Checking Spatial Overlap ===\n")

# Load data
larval <- read_csv('calcofi_larval_chlorophyll_integrated.csv', show_col_types=FALSE)
cefi <- read_csv('cefi_cobalt_chlorophyll_3d.csv', show_col_types=FALSE)

# Filter to overlap period
overlap_larval <- larval %>% 
  filter(date >= as.Date('2000-01-16') & date <= as.Date('2023-01-15'))

cat("Records in temporal overlap:\n")
cat("  Larval:", nrow(overlap_larval), "\n")
cat("  CEFI:", nrow(cefi), "\n")

# Check spatial boundaries
larval_lat_range <- range(overlap_larval$latitude, na.rm=TRUE)
larval_lon_range <- range(overlap_larval$longitude, na.rm=TRUE)
cefi_lat_range <- range(cefi$latitude)
cefi_lon_range <- range(cefi$longitude)

cat("\nSpatial boundaries:\n")
cat("  Larval Lat:", round(larval_lat_range[1], 2), "to", round(larval_lat_range[2], 2), "\n")
cat("  CEFI Lat:  ", round(cefi_lat_range[1], 2), "to", round(cefi_lat_range[2], 2), "\n")
cat("  Larval Lon:", round(larval_lon_range[1], 2), "to", round(larval_lon_range[2], 2), "\n")
cat("  CEFI Lon:  ", round(cefi_lon_range[1], 2), "to", round(cefi_lon_range[2], 2), "\n")

# Check for any spatial overlap
lat_overlap <- max(larval_lat_range[1], cefi_lat_range[1]) <= min(larval_lat_range[2], cefi_lat_range[2])
lon_overlap <- max(larval_lon_range[1], cefi_lon_range[1]) <= min(larval_lon_range[2], cefi_lon_range[2])

cat("\nSpatial overlap exists:\n")
cat("  Latitude:", lat_overlap, "\n")
cat("  Longitude:", lon_overlap, "\n")

if (lat_overlap && lon_overlap) {
  # Find overlapping region
  overlap_lat_min <- max(larval_lat_range[1], cefi_lat_range[1])
  overlap_lat_max <- min(larval_lat_range[2], cefi_lat_range[2])
  overlap_lon_min <- max(larval_lon_range[1], cefi_lon_range[1])
  overlap_lon_max <- min(larval_lon_range[2], cefi_lon_range[2])
  
  cat("\nOverlapping region:\n")
  cat("  Lat:", round(overlap_lat_min, 2), "to", round(overlap_lat_max, 2), "\n")
  cat("  Lon:", round(overlap_lon_min, 2), "to", round(overlap_lon_max, 2), "\n")
  
  # Count records in overlapping region
  larval_in_overlap <- overlap_larval %>%
    filter(latitude >= overlap_lat_min & latitude <= overlap_lat_max &
           longitude >= overlap_lon_min & longitude <= overlap_lon_max)
  
  cefi_in_overlap <- cefi %>%
    filter(latitude >= overlap_lat_min & latitude <= overlap_lat_max &
           longitude >= overlap_lon_min & longitude <= overlap_lon_max)
  
  cat("\nRecords in overlapping region:\n")
  cat("  Larval:", nrow(larval_in_overlap), "\n")
  cat("  CEFI:", nrow(cefi_in_overlap), "\n")
  
  if (nrow(larval_in_overlap) > 0 && nrow(cefi_in_overlap) > 0) {
    cat("\n✓ Potential for matching exists!\n")
    
    # Test matching with broader tolerance
    cat("\nTesting matching with 0.1° tolerance:\n")
    
    cefi_summary <- cefi_in_overlap %>%
      mutate(match_date = as.Date(time, origin = "1970-01-01")) %>%
      mutate(
        match_lat = round(latitude, 1),  # 0.1° tolerance
        match_lon = round(longitude, 1)
      ) %>%
      group_by(match_lat, match_lon, match_date) %>%
      summarise(
        cefi_chl_mean = mean(chlorophyll_mg_m3, na.rm = TRUE),
        .groups = "drop"
      )
    
    test_join <- larval_in_overlap %>%
      mutate(
        match_lat = round(latitude, 1),  # 0.1° tolerance
        match_lon = round(longitude, 1),
        match_date = date
      ) %>%
      left_join(cefi_summary, by = c("match_lat", "match_lon", "match_date"))
    
    matches <- sum(!is.na(test_join$cefi_chl_mean))
    cat("  Matches with 0.1° tolerance:", matches, "\n")
    
    if (matches > 0) {
      cat("  Success! Sample matches:\n")
      matched_records <- test_join %>% 
        filter(!is.na(cefi_chl_mean)) %>%
        select(latitude, longitude, date, cefi_chl_mean) %>%
        head(3)
      print(matched_records)
    }
  }
} else {
  cat("\n✗ No spatial overlap between datasets\n")
}

cat("\n=== Spatial Check Complete ===\n")
