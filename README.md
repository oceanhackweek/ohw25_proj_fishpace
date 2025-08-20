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

TBD

## Lessons Learned

TBD

## References

### Data

-   NASA Goddard Space Flight Center, Ocean Ecology Laboratory, Ocean Biology Processing Group. Plankton, Aerosol, Cloud, ocean Ecosystem (PACE) Chlorophyll Data; NASA OB.DAAC, Greenbelt, MD, USA. <https://dx.doi.org/10.5067/PACE/OCI/L3M/CHL/3.0>

-   NASA Goddard Space Flight Center, Ocean Ecology Laboratory, Ocean Biology Processing Group. Moderate-resolution Imaging Spectroradiometer (MODIS) Aqua Chlorophyll Data; NASA OB.DAAC, Greenbelt, MD, USA. <https://dx.doi.org/10.5067/AQUA/MODIS/L3M/CHL/2022.0>.

-   \[NWFSC data cite\]

-   \[NEFSC data cite\]

-   CalCOFI (2024). California Cooperative Oceanic Fisheries Investigation (CalCOFI). Retrieved from [http://www.calcofi.org](http://www.calcofi.org/)

-   US DOC/NOAA/NMFS. Zooplankton and ichthyoplankton abundance and distribution in the North Atlantic collected by the Ecosystem Monitoring (EcoMon) Project. NOAA National Centers for Environmental Information. [https://www.ncei.noaa.gov/archive/accession/0187513](#0).