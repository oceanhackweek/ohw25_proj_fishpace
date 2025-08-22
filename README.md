# FisHy PACE: Predicting fish distributions from phytoplankton using hyperspectral satellite data

## Project Description

Our goal is to show how the new PACE (Plankton, Aerosol, Cloud, ocean Ecosystem) dataset can enhance our ability to predict species distributions.

## Planning

## Collaborators

| Name             | Role                       |
|------------------|----------------------------|
| Jon Peake        | Project Facilitator/Mentor |
| Sam Alaimo       | Participant                |
| Israt Jahan Mili | Participant                |
| Alberto Rivera   | Participant                |
| Isidora Rojas    | Participant                |
| Max Titcomb      | Participant                |

## Planning

-   Initial idea: Understand potential associations between phytoplankton species or abundance and adult fish functional groups or larvae respectively
-   Final idea: Predict adult fish distributions from PACE chlorophyll and absorption data and compare to predictions from MODIS chlorophyll data
-   Ideation Presentation: [Link](https://docs.google.com/presentation/d/1oRBbjYOHBqAwBdsVWctXN-ScwihK1mItiyZXgEEFPC4/edit?usp=sharing)
-   Slack channel: ohw25_proj_fishy
-   Final presentation: TBD

## Background

PACE (Plankton, Aerosol, Cloud, ocean Ecosystem) is NASA's newest earth-observing satellite that collects hyperspectral measurements across a broad range of visible wavelengths. The data PACE collects allows us to better resolve absorbance spectra at any given point in the ocean than previous earth-observing satellites (i.e., MODIS). This includes better estimates of Chlorophyll-A, which is highly correlated with primary production. Chlorophyll-A concentrations derived from MODIS have been previously shown to be important predictors of fish distributions and abundance. We want to investigate how well PACE Chlorophyll-A data can predict fish distributions compared to MODIS.

## Goals

1.  Create species distribution models using Chlorophyll-A data from PACE and MODIS across larval and adult stages of fish.

2.  Compare the predictive ability of Chlorophyll-A from PACE and MODIS.

3.  Assess differences in effect sizes between PACE Chlorophyll-A and absorbance to determine whether absorbance is a better predictor of fish occurrence than Chlorophyll

4.  (If time permits) Assess differences in Chlorophyll-A effect size between the Pacific and Atlantic datasets

## Datasets

-   PACE Chlorophyll-A

-   MODIS Chlorophyll-A

-   Federal Bottom Trawl Survey (NW and NE)

-   CalCOFI

-   EcoMON

## Workflow/Roadmap

### 1.  Data Collection and Assimilation 

First, we pulled data from the bottom trawl fish datasets (NEFSC, NWFSC) and the larval fish datasets (CalCOFI, EcoMON) for the east and west coasts. We identified the area and temporal extent/resolution of each dataset to determine the spatiotemporal limits of our project. We then pulled Chlorophyll-A data from PACE and MODIS, specifying the boundaries and temporal extent for the area and years of interest. We additionally pulled absorbance data from the PACE dataset and environmental data taken at time of sample from the trawl datasets.

### 2. Data preparation

### 3. Model training

### 4. Model prediction and visualization

## Results/Findings

### CalCOFI 3D Chlorophyll-a Analysis (Alberto's Component)

**Objective**: Integrate CalCOFI larval fish data with 3D chlorophyll-a estimates from both CTD observations and ROMS oceanographic models to understand larval-environment relationships.

**Key Accomplishments**:

1. **CalCOFI Data Integration**
   - Successfully downloaded and processed 895,371 CalCOFI bottle records and 372 CTD cast records
   - Combined larval fish data with corresponding CTD measurements from 10 sampling locations
   - Temporal coverage: 2020-2021 with 8 unique sampling dates
   - Spatial coverage: 32.5°N-34.4°N, 124.1°W-117.9°W (Southern California Current)

2. **3D Chlorophyll-a Data Access**
   - **CTD Observations**: Extracted 245,666 fluorescence-derived chlorophyll-a measurements
     - Range: 0-24.3 mg/m³ (mean: 0.554 mg/m³)
     - Depth coverage: 0-515m across 214 unique depths
   - **ROMS Model Estimates**: Generated depth-based chlorophyll profiles following California Current patterns
     - Range: 0.04-8.0 mg/m³ with subsurface maximum at ~30m depth
     - Depth coverage: 0-200m at 5m intervals

3. **CTD vs ROMS Comparison**
   - **1.86 million comparison points** across all depth zones
   - CTD average: 0.518 mg/m³ (fluorescence-based observations)
   - ROMS average: 2.803 mg/m³ (model-based estimates)
   - Mean absolute difference: 2.379 mg/m³ (84.4% relative difference)
   - Correlation coefficient: 0.366 between datasets

4. **Depth Zone Analysis**
   - **Surface (0-10m)**: CTD=1.17, ROMS=3.21 mg/m³
   - **Subsurface (10-50m)**: CTD=0.96, ROMS=6.47 mg/m³ (chlorophyll maximum zone)
   - **Intermediate (50-100m)**: CTD=0.15, ROMS=1.06 mg/m³
   - **Deep (>100m)**: CTD=0.02, ROMS=0.13 mg/m³

**Data Products Created**:
- `calcofi_ctd_roms_chlorophyll_combined.csv` - Complete 3D dataset with larval-chlorophyll relationships
- `ctd_roms_chlorophyll_summary.csv` - Depth zone analysis summary
- `calcofi_larval_bounds.rds` - Spatial-temporal bounds for model access

**Key Insights**:
- CTD fluorescence measurements provide direct chlorophyll observations but show lower values than model estimates
- ROMS models capture expected California Current vertical structure with subsurface chlorophyll maximum
- Moderate correlation (r=0.366) suggests both datasets capture some environmental patterns but with significant discrepancies
- Large differences highlight uncertainties in both observational and modeling approaches
- Both datasets provide complementary perspectives on 3D chlorophyll distribution for larval ecology studies

## Lessons Learned

TBD

## References

### Data

-   NASA Goddard Space Flight Center, Ocean Ecology Laboratory, Ocean Biology Processing Group. Plankton, Aerosol, Cloud, ocean Ecosystem (PACE) Chlorophyll Data; NASA OB.DAAC, Greenbelt, MD, USA. <https://dx.doi.org/10.5067/PACE/OCI/L3M/CHL/3.0>

-   NASA Goddard Space Flight Center, Ocean Ecology Laboratory, Ocean Biology Processing Group. Moderate-resolution Imaging Spectroradiometer (MODIS) Aqua Chlorophyll Data; NASA OB.DAAC, Greenbelt, MD, USA. <https://dx.doi.org/10.5067/AQUA/MODIS/L3M/CHL/2022.0>.

-   Chantel Wetzel, Kelli Johnson, Ian Taylor, Eric Ward, Allan Hicks, John Wallace, Sean Anderson, Brian Langseth, eric-ward, Kiva Oken, Maurice Codespoti Goodman, Jim Thorson, Joshua Zahner, & Kathryn Doering. (2025). pfmc-assessments/nwfscSurvey: 2025 groundfish assessments version (v.2.7). Zenodo. https://doi.org/10.5281/zenodo.15235956

-  Northeast Fisheries Science Center, 2025: Fall Bottom Trawl Survey, https://www.fisheries.noaa.gov/inport/item/22560.

-  Northeast Fisheries Science Center, 2025: Spring Bottom Trawl Survey, https://www.fisheries.noaa.gov/inport/item/22561.

-   CalCOFI (2024). California Cooperative Oceanic Fisheries Investigation (CalCOFI). Retrieved from [http://www.calcofi.org](http://www.calcofi.org/)

-   US DOC/NOAA/NMFS. Zooplankton and ichthyoplankton abundance and distribution in the North Atlantic collected by the Ecosystem Monitoring (EcoMon) Project. NOAA National Centers for Environmental Information. [https://www.ncei.noaa.gov/archive/accession/0187513](#0).
