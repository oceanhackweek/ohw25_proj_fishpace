# Fix CEFI COBALT data export issue
# The extraction completed but failed to save due to list/matrix columns

library(dplyr)
library(readr)

cat("Fixing CEFI COBALT data export...\n")

# Check if we have the data in the R environment from the previous run
# If not, we'll need to re-run the extraction with the fix
if (!exists("cefi_chl_data")) {
  cat("CEFI data not found in environment. Please re-run 03_cefi_roms_chlorophyll_access.R\n")
  cat("The script has been updated to fix the export issue.\n")
} else {
  cat("Found CEFI data in environment. Fixing and saving...\n")
  
  # Ensure all columns are atomic (not lists) before saving
  cefi_chl_data_fixed <- cefi_chl_data %>%
    mutate(
      longitude = as.numeric(longitude),
      latitude = as.numeric(latitude), 
      depth_m = as.numeric(depth_m),
      time = as.numeric(time),
      chlorophyll_mg_m3 = as.numeric(chlorophyll_mg_m3)
    )
  
  # Save CEFI chlorophyll data
  write_csv(cefi_chl_data_fixed, "cefi_cobalt_chlorophyll_3d.csv")
  cat("✓ Saved CEFI COBALT chlorophyll data to: cefi_cobalt_chlorophyll_3d.csv\n")
  
  cat("Data summary:\n")
  cat("  Total records:", nrow(cefi_chl_data_fixed), "\n")
  cat("  Chlorophyll range:", min(cefi_chl_data_fixed$chlorophyll_mg_m3), "to", 
      max(cefi_chl_data_fixed$chlorophyll_mg_m3), "mg/m³\n")
  cat("  Depth range:", min(cefi_chl_data_fixed$depth_m), "to", 
      max(cefi_chl_data_fixed$depth_m), "m\n")
}

cat("Export fix complete.\n")
