
# CalCOFI 3D Chlorophyll-Larval Fish Analysis - Complete Workflow

## ✅ **Project Complete - 3D Spatial Visualization Ready**

### Real 3D Biogeochemical Model Data Integration
- **NOAA CEFI Regional MOM6 COBALT** - Northeast Pacific biogeochemical model
- **Real chlorophyll-a data** (not synthetic) from ocean circulation model
- **4D structure**: longitude, latitude, depth (0-200m), time (2000-2023)
- **CalCOFI larval fish abundance** integrated with environmental data
- **Interactive 3D visualization** combining all data sources

## Production Scripts (Run in Order)

### 1. Data Preparation
- `00_combined_larval_download.R` - **NEW**: Combined ERDDAP larval data download and processing
- `00_calcofi_full_historical_download.R` - Download historical CalCOFI data (1990-2024) [LEGACY]
- `00_create_larval_datasets.R` - Create standardized larval datasets from ERDDAP [LEGACY]

### 2. **CEFI COBALT 3D Chlorophyll Pipeline** ⭐
- `02_extract_larval_bounds.R` - Extract spatial-temporal bounds from larval data
- `03_cefi_roms_chlorophyll_access.R` - Access NOAA CEFI COBALT 3D chlorophyll data
- `04_integrate_larval_chlorophyll.R` - Integrate larval data with CEFI chlorophyll
- `05_extract_ctd_chlorophyll.R` - Extract CTD chlorophyll and compare with CEFI

### 3. **3D Visualization** 🎯
- `06_visualize_3d_chlorophyll.R` - **MAIN**: Unified 3D spatial visualization
- `07_unified_3d_spatial_visualization.R` - [REMOVED - replaced by 06]

### 4. Data Integration (Optional)
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

## **3D Visualization Features** 🎯

### Interactive 3D Spatial Plot
- **CEFI COBALT chlorophyll** (squares) - Environmental context from biogeochemical model
- **CTD chlorophyll observations** (triangles) - Real observational data when available
- **CalCOFI larval abundance** (circles) - Fish larvae counts by species and location
- **Depth representation** - Fixed depths per tow type for scientific accuracy
- **Color scale** - Unified viridis palette for chlorophyll concentrations
- **Marker sizes** - Proportional to larval abundance counts

### Depth Assignment Logic
- **CB (Bongo)**: 35m depth - Representative of 0-210m oblique tows
- **MT (Manta)**: 15m depth - Surface neuston sampling (0-8cm actual)
- **PV (Pairovet)**: 5m depth - Near-surface sampling
- **Surface**: 5m depth - Surface tows
- **Oblique**: 60m depth - Mid-water column sampling

## **Production Status** 📊

### ✅ **All Objectives Complete**
- ✅ CEFI COBALT 3D chlorophyll data integration
- ✅ CalCOFI larval fish data processing and filtering
- ✅ CTD observational data extraction and comparison
- ✅ Spatial-temporal matching between datasets
- ✅ Interactive 3D visualization with proper depth representation
- ✅ Scientific depth assignment based on CalCOFI sampling protocols
- ✅ Unified color scales and marker sizing for clarity
- ✅ Combined data download script for efficiency

## **Final Analysis Results** 🔬
- **Complete 3D spatial visualization** integrating all data sources
- **Real biogeochemical model** (CEFI COBALT) chlorophyll data
- **22,000+ larval fish records** with environmental context
- **Depth-stratified analysis** using representative sampling depths
- **Interactive HTML output** for exploration and presentation

## **Data Coverage Summary**
- **Temporal**: 2000-2023 (24 years, CEFI model period)
- **Spatial**: Northeast Pacific California Current System
- **Species**: 518+ larval fish species (filtered to model coverage)
- **Environmental**: 3D chlorophyll from CEFI COBALT + CTD observations
- **Depth**: 0-200m euphotic zone with realistic tow depth assignments

