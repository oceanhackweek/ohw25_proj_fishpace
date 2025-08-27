# FisHy PACE: Predicting fish distributions from phytoplankton using hyperspectral satellite data

## Project Description

Our goal is to show how the new PACE (Plankton, Aerosol, Cloud, ocean Ecosystem) dataset can enhance our ability to predict species distributions.

## Collaborators

| Name             | Role                       | Affiliation                            |  Github        |  Email                     |
|------------------|----------------------------|----------------------------------------|--------------- |----------------------------|
| Jon Peake        | Project Facilitator/Mentor |NOAA Fisheries Open Science             |[jonpeake]([url](https://github.com/jonpeake))        |jonathan.peake@noaa.gov     |
| Sam Alaimo       | Participant                |Rutgers University                      |[salaimo26 ]([url](https://github.com/salaimo26))      |alaimo@marine.rutgers.edu   |
| Israt Jahan Mili | Participant                |University of Massachusetts--Dartmouth  |[israt-mili]([url](https://github.com/israt-mili))      |mmili@umassd.edu            |
| Alberto Rivera   | Participant                |Scripps Institution of Oceanography       |[buzoAlberto]([url](https://github.com/buzoAlberto))     |alr052@ucsd.edu             | 
| Isidora Rojas    | Participant                |Scripps Institution of Oceanography       |[isidora-rojas ]([url](https://github.com/isidora-rojas))  |i1rojas@ucsd.edu            |  
| Max Titcomb      | Participant                |Scripps Institution of Oceanography       |[maxtitcomb]([url](https://github.com/maxtitcomb))      |mctitcomb@ucsd.edu          |


## Planning

-   Initial idea: Understand potential associations between phytoplankton species or abundance and adult fish functional groups or larvae respectively
-   Final idea: Predict adult fish distributions from PACE chlorophyll and absorption data and compare to predictions from MODIS chlorophyll data
-   Ideation Presentation: [Link](https://docs.google.com/presentation/d/1oRBbjYOHBqAwBdsVWctXN-ScwihK1mItiyZXgEEFPC4/edit?usp=sharing)
-   Slack channel: ohw25_proj_fishy
-   Final presentation: [Link](https://docs.google.com/presentation/d/1oRBbjYOHBqAwBdsVWctXN-ScwihK1mItiyZXgEEFPC4/edit?usp=sharing)

## Background

PACE (Plankton, Aerosol, Cloud, ocean Ecosystem) is NASA's newest earth-observing satellite that collects hyperspectral measurements across a broad range of visible wavelengths. The data PACE collects allows us to better resolve absorbance spectra at any given point in the ocean than previous earth-observing satellites (i.e., MODIS). This includes better estimates of Chlorophyll-A, which is highly correlated with primary production. Chlorophyll-A concentrations derived from MODIS have been previously shown to be important predictors of fish distributions and abundance. We want to investigate how well PACE Chlorophyll-A data can predict fish distributions compared to MODIS.

## Goals

1.  Establish and proof of concept between the ROMS Chlorophyll-A model and CalCOFI datasets

2.  Create species distribution models using Chlorophyll-A data from PACE across adult stages of fish.

3.  Compare the predictive ability of Chlorophyll-A from PACE.

4.  Assess differences in effect sizes between PACE Chlorophyll-A and absorbance to determine whether absorbance is a better predictor of fish occurrence than Chlorophyll

5.  (If time permits) Assess differences in Chlorophyll-A effect size between the Pacific and Atlantic datasets

## Datasets

-   PACE Chlorophyll-A

-   Federal Bottom Trawl Survey (NW and NE)

-   CalCOFI (West Coast Larval Dataset)

-   EcoMON (East Coast Larval Dataset)

## Workflow/Roadmap

### 1.  Data Collection and Assimilation 

First, we pulled data from the bottom trawl fish datasets (NEFSC, NWFSC) and the larval fish datasets (CalCOFI, EcoMON) for the east and west coasts. We identified the area and temporal extent/resolution of each dataset to determine the spatiotemporal limits of our project. We then pulled Chlorophyll-A data from PACE and MODIS, specifying the boundaries and temporal extent for the area and years of interest. We additionally pulled absorbance data from the PACE dataset and environmental data taken at time of sample from the trawl datasets.

### 2. Data preparation

Trawl Data: Trawl data was prepared by subsetting only the fish species that were caught in the surveys. We focused on year 2024 to match the PACE data range. 
  
  East Coast: Since the biological and environmental data is in separate .csv files, these two were merged together with Latitude, Longitude, Surface and Bottom Temperature, Surface and Bottom Salinity and Average Depth.
  selected. The final data frame consisted of rows corresponding to each individual trawl ID and columns corresponding to a species caught in the trawl, and the environmental data associated with each respective trawl ID.

West Coast: 
Trawl data was derived from the Northwest Fisheries Science Center (NWFSC) Survey package here: https://pfmc-assessments.github.io/nwfscSurvey/index.html

<img width="2400" height="1800" alt="survey_sites_map (1)" src="https://github.com/user-attachments/assets/1454ef5a-a470-4c21-aed8-b8c6ec252b1e" />


PACE Data: https://pace.gsfc.nasa.gov/

### 3. Model training
Response & covariate. For each species with sufficient data, I modeled raw CPUE (individuals per ha) from the NWFSC West Coast trawl survey as a function of PACE chlorophyll-a:

$$
\log \big( \mathbb{E}[\text{CPUE}] \big) = \beta_0 + \beta_1 \cdot \text{chlor\_a\_standardized} + \text{spatial random field}
$$


  •	**Response:** derivation of catch per unit effort in numbers of individuals per hectare ordinarily estimated as the expanded haul catch in numbers divided by the area swept by the net.
	•	**Family/link:** Tweedie with log link (appropriate for many zeros + right-skewed positive values).
	•	**Covariate:** chlor_a_standardized (PACE Chl-a z-scored).
	•	**Species inclusion:** kept species present in ≥ 50 trawls with non-zero catch.
	•	**Spatial structure:** barrier mesh over the coastline (North America land polygons projected to UTM 10N and scaled to km) with spatial = “on”, spatiotemporal = “off”.
	•	**Fitting:** sdmTMB with sanity() gating; species failing sanity checks were skipped.
	•	**Train/test split:** random 80/20 by trawl (slice_sample(prop = 0.2) for test set).
	•	**Prediction grid:** satellite grid with UTM km coordinates (pace_grid_no_na) for mapping predictions.

This setup let me estimate a single coefficient per species for the marginal effect of PACE Chl-a on CPUE while accounting for spatial autocorrelation.

### 4. Model prediction and visualization
For each species that passed sanity checks I generated a standardized four-panel figure:
	•	A — Observed CPUE map (training): bubble map of observed CPUE over land basemap.
	•	B — Predicted CPUE raster (grid): model predictions on the PACE grid (log-scaled fill) with coastline mask.
	•	C — Spatial residuals (held-out): points colored by Pred − Obs and sized by absolute error to show regional over/under-prediction patterns.
	•	D — Bars (held-out): side-by-side Predicted vs Observed CPUE ordered south→north to visualize bias along latitude.

 <img width="4000" height="3200" alt="arrowtooth_flounder_cpue_numbers_per_ha_der_final_plot (1)" src="https://github.com/user-attachments/assets/0b6ce32f-a6fe-44f7-b161-eb691f05d0bb" />

I also extracted fixed-effects coefficients and 90% CIs for chlor_a_standardized across all species and compiled them into a single table. Using life-history joins, I produced summary coefficient plots colored by dominant movement and by adult prey category.
<img width="3600" height="2800" alt="resident_mobile_chla" src="https://github.com/user-attachments/assets/2bd913cf-0a98-49de-a30d-67cfbcb99fab" />

<img width="3600" height="2800" alt="trophic_level_chla" src="https://github.com/user-attachments/assets/58ba33b3-095e-43c1-b876-c5844e81f5cf" />

## Results/Findings

**Most species:** Chl-a effect on adult CPUE is small/uncertain (90% CIs often cross 0).
**Some negatives:** A minority show negative associations with Chl-a.
**Validation:** Held-out bars/residual maps show modest skill with regional bias—Chl-a alone doesn’t explain adult demersal CPUE.

## Lessons Learned & Next Steps

Future work will integrate additional PACE products (e.g., attenuation, absorption, backscatter) and external plankton community data from MOANA ERDDAP to test whether optical properties or plankton group composition improve predictions. Exploring time-varying coefficients and spatiotemporal models will help assess how relationships shift across seasons and years, providing a clearer picture of when and where PACE data best explain fish distributions.

## References

### Data

-   NASA Goddard Space Flight Center, Ocean Ecology Laboratory, Ocean Biology Processing Group. Plankton, Aerosol, Cloud, ocean Ecosystem (PACE) Chlorophyll Data; NASA OB.DAAC, Greenbelt, MD, USA. <https://dx.doi.org/10.5067/PACE/OCI/L3M/CHL/3.0>

-   NASA Goddard Space Flight Center, Ocean Ecology Laboratory, Ocean Biology Processing Group. Moderate-resolution Imaging Spectroradiometer (MODIS) Aqua Chlorophyll Data; NASA OB.DAAC, Greenbelt, MD, USA. <https://dx.doi.org/10.5067/AQUA/MODIS/L3M/CHL/2022.0>.

-   Chantel Wetzel, Kelli Johnson, Ian Taylor, Eric Ward, Allan Hicks, John Wallace, Sean Anderson, Brian Langseth, eric-ward, Kiva Oken, Maurice Codespoti Goodman, Jim Thorson, Joshua Zahner, & Kathryn Doering. (2025). pfmc-assessments/nwfscSurvey: 2025 groundfish assessments version (v.2.7). Zenodo. https://doi.org/10.5281/zenodo.15235956

-  Northeast Fisheries Science Center, 2025: Fall Bottom Trawl Survey, https://www.fisheries.noaa.gov/inport/item/22560.

-  Northeast Fisheries Science Center, 2025: Spring Bottom Trawl Survey, https://www.fisheries.noaa.gov/inport/item/22561.

-   CalCOFI (2024). California Cooperative Oceanic Fisheries Investigation (CalCOFI). Retrieved from [http://www.calcofi.org](http://www.calcofi.org/)

-   US DOC/NOAA/NMFS. Zooplankton and ichthyoplankton abundance and distribution in the North Atlantic collected by the Ecosystem Monitoring (EcoMon) Project. NOAA National Centers for Environmental Information. [https://www.ncei.noaa.gov/archive/accession/0187513](#0).
