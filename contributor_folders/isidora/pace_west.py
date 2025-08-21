import os, re
import earthaccess
import xarray as xr
import pandas as pd
import numpy as np

# choose times and lat/lon
temporal = ("2024-06-04", "2024-11-11")

# login to nasa
auth = earthaccess.login()

results_day = earthaccess.search_data(
    short_name = "PACE_OCI_L3M_CHL",
    temporal = temporal,
    granule_name="*.DAY.*.4km.*"
)

# opens files
fileset = earthaccess.open(results_day)

# Extract dates from file paths
date_pattern = re.compile(r"PACE_OCI\.(\d{8})")

dates = []
for f in fileset:
    match = date_pattern.search(f.path)
    if not match:
        raise ValueError(f"Could not extract date from: {f.path}")
    date_str = match.group(1)
    dates.append(pd.to_datetime(date_str, format="%Y%m%d"))

# Sanity check
if len(dates) != len(fileset):
    raise ValueError(f"Mismatch: found {len(dates)} dates for {len(fileset)} files")

CHL = xr.open_mfdataset(
    fileset,
    combine="nested",
    concat_dim="time"
)

# Overwrite with correct dates
CHL = CHL.assign_coords(time=("time", dates))

CHL_west = CHL.sel(lat=lat_west, lon=lon_west)
CHL_west = CHL_west.chlor_a.sel(time=time, method='nearest').where(lambda x: x > 0)  # drop zeros for LogNorm
CHL_west = CHL_west.clip(min=0.01)





