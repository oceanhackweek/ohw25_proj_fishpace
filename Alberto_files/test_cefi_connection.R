# Test CEFI COBALT connection with your working example
library("ncdf4")

cat("Testing CEFI COBALT connection...\n")

# Specify the OPeNDAP server URL (using regular grid output)
url <- "http://psl.noaa.gov/thredds/dodsC/Projects/CEFI/regional_mom6/cefi_portal/northeast_pacific/full_domain/hindcast/monthly/regrid/r20250509/chl.nep.full.hcast.monthly.regrid.r20250509.199301-202412.nc"

tryCatch({
  # Open a NetCDF file lazily and remotely
  ncopendap <- nc_open(url)
  cat("✓ Successfully connected to CEFI COBALT dataset\n")
  
  # Read the coordinate into memory
  lon <- ncvar_get(ncopendap, "lon")
  lat <- ncvar_get(ncopendap, "lat")
  time <- ncvar_get(ncopendap, "time", start = c(1), count = c(1))
  
  cat("Dataset dimensions:\n")
  cat("  Longitude points:", length(lon), "\n")
  cat("  Latitude points:", length(lat), "\n")
  cat("  Longitude range:", min(lon), "to", max(lon), "\n")
  cat("  Latitude range:", min(lat), "to", max(lat), "\n")
  cat("  First time value:", time, "\n")
  
  # Check if depth dimension exists
  if ("z_l" %in% names(ncopendap$dim)) {
    depth <- ncvar_get(ncopendap, "z_l")
    cat("  Depth levels:", length(depth), "\n")
    cat("  Depth range:", min(depth), "to", max(depth), "m\n")
    
    # Read a 4D slice of the data (lon, lat, depth, time)
    chl <- ncvar_get(ncopendap, "chl", start = c(1, 1, 1, 1), count = c(-1, -1, -1, 1))
  } else {
    # Read a 3D slice (lon, lat, time) - surface only
    chl <- ncvar_get(ncopendap, "chl", start = c(1, 1, 1), count = c(-1, -1, 1))
  }
  
  cat("Chlorophyll data:\n")
  cat("  Dimensions:", dim(chl), "\n")
  cat("  Valid values:", sum(!is.na(chl)), "out of", length(chl), "\n")
  cat("  Range:", min(chl, na.rm = TRUE), "to", max(chl, na.rm = TRUE), "mg/m³\n")
  
  # Close connection
  nc_close(ncopendap)
  cat("✓ CEFI COBALT test completed successfully\n")
  
}, error = function(e) {
  cat("✗ CEFI COBALT connection failed:", e$message, "\n")
})
