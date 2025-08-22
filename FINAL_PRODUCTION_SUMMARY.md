# CalCOFI Data Processing for ROMS Integration

## Repository Overview

This repository contains essential scripts to process CalCOFI larval fish data and extract environmental data for integration with ROMS 3D oceanographic models.

## Core Production Scripts (Numbered Execution Order)

### 01_combine_calcofi_larval_datasets.R

**Function**: Combines CalCOFI larval count and stage data into unified dataset
**Dependencies**: `dplyr`, `readr`
**Inputs**:

- `Larvae.csv` (67.9 MB) - Total larval counts
- `LarvaeStages.csv` (20.3 MB) - Stage-specific counts
  **Primary Output**: `combined_larval_dataset.csv` (36.0 MB, 192,082 records)
  **Status**: ✅ Complete and tested

### 02_convert_ecomon_wide_to_long.R

**Function**: Converts EcoMon wide format (275+ species columns) to long format
**Dependencies**: `dplyr`, `readr`, `tidyr`
**Inputs**: `0187513/4.4/data/0-data/EcoMon_Plankton_Data_v3_10.csv` (26.0 MB)
**Primary Output**: `ecomon_plankton_long_format.csv` (88.0 MB, 1,087,010 records)
**Additional Outputs**:

- `ecomon_summary_by_density_type.csv`
- `ecomon_top_species.csv`
  **Status**: ✅ Complete and tested

### 03_check_ecomon_recent_data.R

**Function**: Validates recent data availability (2023-2024) and extracts fish larvae
**Dependencies**: `dplyr`, `readr`, `lubridate`
**Inputs**: EcoMon dataset (via script 02)
**Primary Output**: `ecomon_2023_2024_data.csv` (1.97 MB, 18,454 records)
**Additional Outputs**: `ecomon_temporal_coverage.csv`
**Key Finding**: 352 fish larval records from 2023
**Status**: ✅ Complete and tested

### 04_create_cruise_id_mappings.R

**Function**: Creates standardized cruise ID mappings between datasets
**Dependencies**: `dplyr`, `readr`
**Inputs**: Combined larval dataset (from script 01)
**Primary Output**: `simple_cruise_id_mapping.csv` (4.8 KB)
**Additional Output**: `larval_to_ctd_cruise_id_mapping.csv` (11.1 KB)
**Status**: ✅ Complete and tested

### 05_examine_calcofi_sql_structure.R

**Function**: Analyzes CalCOFI SQL database structure for CTD data extraction
**Dependencies**: `dplyr`, `readr`
**Inputs**: `CalCOFI_Database_194903-202105_sql_16October2023/` (SQL dump)
**Primary Output**: Database structure analysis and coordinate matching
**Status**: ✅ Complete and tested

### 06_extract_ctd_environmental_data.R

**Function**: Extracts CTD oceanographic data for larval sampling locations
**Dependencies**: `dplyr`, `readr`
**Inputs**: SQL database analysis (from script 05)
**Primary Output**: `extracted_ctd_data_matched_locations.csv` (49.7 KB, 199 records)
**Additional Outputs**:

- `ctd_key_oceanographic_variables.csv` (17.3 KB)
- `ctd_data_summary_by_location.csv`
  **Status**: ✅ Complete and tested

### 07_calculate_dataset_bounds.R

**Function**: Calculates geographic and temporal bounds of combined datasets
**Dependencies**: `dplyr`, `readr`, `lubridate`
**Inputs**: Combined larval dataset (from script 01)
**Primary Output**: `larval_dataset_bounding_box.csv`
**Key Results**: 39.1 years (1984-2023), Pacific coverage 18.5°N-54.3°N
**Status**: ✅ Complete and tested

## Final Dataset Specifications

### Combined CalCOFI Larval Dataset

- **Records**: 192,082 species observations
- **Time Range**: 1984-2023 (39.1 years)
- **Geographic Coverage**: West Coast Pacific (18.5°N-54.3°N, -179.8°W to -115.8°W)
- **Species**: 160+ taxa with scientific names
- **Format**: Long format (one row per species observation)
- **File Size**: 36.0 MB

### EcoMon Long Format Dataset

- **Records**: 1,087,010 species observations
- **Time Range**: 1977-2023 (47 years)
- **Geographic Coverage**: East Coast Atlantic (25.02°N-45.27°N, -76.37°W to -65.33°W)
- **Species**: 118 taxa with abbreviated codes
- **Density Measures**: Dual standardization (10M², 100M³)
- **Format**: Long format with environmental data
- **File Size**: 88.0 MB

### CTD Environmental Data

- **Records**: 199 matched oceanographic profiles
- **Variables**: Temperature, salinity, oxygen, nutrients, chlorophyll
- **Coverage**: Locations matching larval sampling events
- **File Size**: 49.7 KB

## System Requirements

- **R Version**: 4.0+ recommended
- **Memory**: ~2GB RAM for processing
- **Disk Space**: ~200MB for outputs
- **Processing Time**: ~5-10 minutes total

## R Package Dependencies

```r
install.packages(c("dplyr", "readr", "tidyr", "lubridate"))
```

## Execution Workflow

```bash
# Execute in numbered order
Rscript 01_combine_calcofi_larval_datasets.R
Rscript 02_convert_ecomon_wide_to_long.R  
Rscript 03_check_ecomon_recent_data.R
Rscript 04_create_cruise_id_mappings.R
Rscript 05_examine_calcofi_sql_structure.R
Rscript 06_extract_ctd_environmental_data.R
Rscript 07_calculate_dataset_bounds.R
```

## Key Data Transformations

### CalCOFI Processing

1. **Temporal Alignment**: Matches records by cruise, time, and location
2. **Format Standardization**: Combines total and stage-specific counts
3. **Data Source Tracking**: Maintains provenance (larvae_counts vs larvae_stages)

### EcoMon Processing

1. **Wide to Long Conversion**: Transforms 275+ species columns to rows
2. **Density Standardization**: Separates 10M² and 100M³ measures
3. **Species Code Mapping**: Uses abbreviated taxonomic codes

### Environmental Integration

1. **Coordinate Matching**: Flexible precision matching for CTD locations
2. **Temporal Alignment**: Links oceanographic conditions to biological sampling
3. **Variable Selection**: Key oceanographic parameters for ecological analysis

## Quality Control Features

- Zero/NA value filtering
- Coordinate precision validation
- Temporal alignment verification
- Data source tracking
- Geographic bounds checking
- Species frequency validation

## Repository Structure

```
CalCOFI-fish-larvae-data/
├── 01_combine_calcofi_larval_datasets.R      # Core CalCOFI processing
├── 02_convert_ecomon_wide_to_long.R          # Core EcoMon processing  
├── 03_check_ecomon_recent_data.R             # Data validation
├── 04_create_cruise_id_mappings.R            # ID standardization
├── 05_examine_calcofi_sql_structure.R        # Database analysis
├── 06_extract_ctd_environmental_data.R       # Environmental data
├── 07_calculate_dataset_bounds.R             # Bounds calculation
├── combined_larval_dataset.csv               # Primary CalCOFI output
├── ecomon_plankton_long_format.csv          # Primary EcoMon output
├── extracted_ctd_data_matched_locations.csv # Environmental data
└── [additional output files]
```
