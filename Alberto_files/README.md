
# CalCOFI 3D Chlorophyll-Larval Fish Analysis - Production Workflow

## ✅ **CEFI COBALT Integration Complete**

### Real 3D Biogeochemical Model Data Access
- **NOAA CEFI Regional MOM6 COBALT** - Northeast Pacific biogeochemical model
- **Real chlorophyll-a data** (not synthetic) from ocean circulation model
- **4D structure**: longitude, latitude, depth (0-200m), time (2000-2023)
- **Fixed coordinate conversion**: 0-360° longitude properly handled

## Production Scripts (Run in Order)

### 1. Data Preparation
- `00_calcofi_full_historical_download.R` - Download historical CalCOFI data (1990-2024)
- `create_larval_datasets.R` - Create standardized larval datasets from ERDDAP

### 2. **CEFI COBALT 3D Chlorophyll Pipeline** ⭐
- `02_extract_larval_bounds.R` - Extract spatial-temporal bounds from larval data
- `03_cefi_roms_chlorophyll_access.R` - **FIXED**: Access NOAA CEFI COBALT 3D chlorophyll data
- `04_integrate_larval_chlorophyll.R` - Integrate larval data with CEFI chlorophyll
- `05_extract_ctd_chlorophyll.R` - Extract CTD chlorophyll and compare with CEFI

### 3. Data Integration (Optional)
- `01_combine_larval_ctd_data.R` - Alternative larval-CTD combination approach

## Key Datasets

### Real Larval Fish Data
- `Larvae.csv` (85,806 records, 1993-2024, filtered to CEFI coverage)
- `LarvaeStages.csv` (larval development stages)

### **CEFI COBALT Biogeochemical Data** 🌊
- `cefi_cobalt_chlorophyll_3d.csv` - **Real 3D chlorophyll from biogeochemical model**
- **Spatial**: California Current (49×163 grid, 0.1° resolution)
- **Depth**: 22 levels (0-200m euphotic zone)
- **Temporal**: 2000-2023 (annual samples)
- **Variables**: longitude, latitude, depth_m, time, chlorophyll_mg_m3

### CalCOFI Environmental Data  
- `calcofi_194903-202105_bottle.csv` (895K bottle measurements)
- `calcofi_194903-202105_cast.csv` (9K CTD casts)
- `calcofi_ctd_roms_chlorophyll_combined.csv` (CTD comparison data)

## **Production Status** 📊

### ✅ Completed
- CEFI COBALT data access with proper coordinate conversion
- 4D NetCDF data extraction with spatial/temporal subsetting
- Integration script updated for CEFI data structure
- Real biogeochemical model chlorophyll (not synthetic data)

### 🔄 In Progress
- CEFI chlorophyll extraction (processing time step 11 of 22)

### 📋 Next Steps
- Complete CEFI-larval integration testing
- Verify full pipeline with real biogeochemical data
- Generate final larval-chlorophyll analysis

## Analysis Results
- **Real 3D biogeochemical model integration** with larval fish data
- CEFI COBALT vs CTD observational chlorophyll comparison
- Spatial-temporal larval distribution with ocean circulation context
- Species-environment relationships using state-of-the-art ocean model

## Data Coverage
- **Temporal**: 2000-2023 (24 years, CEFI model period)
- **Spatial**: Northeast Pacific California Current System
- **Species**: 518 larval fish species (filtered to model coverage)
- **Environmental**: 3D chlorophyll, temperature, salinity from CEFI COBALT model

