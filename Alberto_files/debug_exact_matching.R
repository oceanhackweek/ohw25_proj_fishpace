# Debug exact matching issue between CEFI and larval data
library(readr)
library(dplyr)

cat("=== Debugging Exact Matching Issue ===\n")

# Load data
larval <- read_csv('calcofi_larval_chlorophyll_integrated.csv', show_col_types=FALSE)
cefi <- read_csv('cefi_cobalt_chlorophyll_3d.csv', show_col_types=FALSE)

# Filter to overlapping region and time
overlap_larval <- larval %>% 
  filter(date >= as.Date('2000-01-16') & date <= as.Date('2023-01-15')) %>%
  filter(latitude >= 28.07 & latitude <= 41.98) %>%
  filter(longitude >= -129.83 & longitude <= -117.2)

overlap_cefi <- cefi %>%
  filter(latitude >= 28.07 & latitude <= 41.98) %>%
  filter(longitude >= -129.83 & longitude <= -117.2)

cat("Records in overlap region:\n")
cat("  Larval:", nrow(overlap_larval), "\n")
cat("  CEFI:", nrow(overlap_cefi), "\n")

if (nrow(overlap_larval) > 0 && nrow(overlap_cefi) > 0) {
  # Create matching keys with different tolerances
  cat("\nTesting different spatial tolerances:\n")
  
  # Test 0.5° tolerance
  cefi_summary_05 <- overlap_cefi %>%
    mutate(
      match_lat = round(latitude * 2) / 2,  # 0.5° grid
      match_lon = round(longitude * 2) / 2,
      match_date = as.Date(time, origin = "1970-01-01")
    ) %>%
    group_by(match_lat, match_lon, match_date) %>%
    summarise(cefi_chl_mean = mean(chlorophyll_mg_m3, na.rm = TRUE), .groups = "drop")
  
  test_05 <- overlap_larval %>%
    mutate(
      match_lat = round(latitude * 2) / 2,
      match_lon = round(longitude * 2) / 2,
      match_date = date
    ) %>%
    left_join(cefi_summary_05, by = c("match_lat", "match_lon", "match_date"))
  
  matches_05 <- sum(!is.na(test_05$cefi_chl_mean))
  cat("  0.5° tolerance:", matches_05, "matches\n")
  
  # Test 1.0° tolerance
  cefi_summary_10 <- overlap_cefi %>%
    mutate(
      match_lat = round(latitude),  # 1.0° grid
      match_lon = round(longitude),
      match_date = as.Date(time, origin = "1970-01-01")
    ) %>%
    group_by(match_lat, match_lon, match_date) %>%
    summarise(cefi_chl_mean = mean(chlorophyll_mg_m3, na.rm = TRUE), .groups = "drop")
  
  test_10 <- overlap_larval %>%
    mutate(
      match_lat = round(latitude),
      match_lon = round(longitude),
      match_date = date
    ) %>%
    left_join(cefi_summary_10, by = c("match_lat", "match_lon", "match_date"))
  
  matches_10 <- sum(!is.na(test_10$cefi_chl_mean))
  cat("  1.0° tolerance:", matches_10, "matches\n")
  
  if (matches_10 > 0) {
    cat("\n✓ Success with 1.0° tolerance!\n")
    cat("Sample matches:\n")
    matched_records <- test_10 %>% 
      filter(!is.na(cefi_chl_mean)) %>%
      select(latitude, longitude, date, match_lat, match_lon, match_date, cefi_chl_mean) %>%
      head(5)
    print(matched_records)
  } else {
    # Check temporal matching separately
    cat("\nChecking temporal matching:\n")
    larval_dates <- unique(overlap_larval$date)
    cefi_dates <- unique(as.Date(overlap_cefi$time, origin = "1970-01-01"))
    
    cat("  Unique larval dates:", length(larval_dates), "\n")
    cat("  Unique CEFI dates:", length(cefi_dates), "\n")
    cat("  Sample larval dates:", as.character(head(sort(larval_dates), 5)), "\n")
    cat("  Sample CEFI dates:", as.character(head(sort(cefi_dates), 5)), "\n")
    
    # Check for any date overlap
    date_overlap <- intersect(larval_dates, cefi_dates)
    cat("  Overlapping dates:", length(date_overlap), "\n")
    if (length(date_overlap) > 0) {
      cat("  Sample overlapping dates:", as.character(head(date_overlap, 5)), "\n")
    }
  }
} else {
  cat("No records in overlap region!\n")
}

cat("\n=== Debug Complete ===\n")
