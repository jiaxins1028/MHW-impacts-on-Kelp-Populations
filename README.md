[![DOI](https://zenodo.org/badge/759275381.svg)](https://doi.org/10.5281/zenodo.15009284)

# MHW-impacts-on-Kelp-Populations
This repository contains the code and workflows used to analyse the relationship between marine heatwaves (MHWs) and long-term observational kelp records across multiple *Ecklonia radiata* populations.

Due to their size, some raw datasets must be accessed directly from the providers. However, all datasets are freely available, and the instructions below explain exactly how to download them and where to place the files. Instructions of downloading and using the raw datasets are provided in `rawdata_download_use.md`.
MHW calculations are performed using xmhw: https://github.com/coecms/xmhw.

| Raw data | Source |
|-----:|---------------|
| Long-term Reef Monitoring Program kelp cover | Australia’s National Reef Monitoring Network. Raw data and instructions can be accessed from https://catalogue-imos.aodn.org.au/geonetwork/srv/eng/catalog.search#/metadata/ec424e4f-0f55-41a5-a3f2-726bc4541947 |
| Long-term observations of Ecklonia canopy cover in Kalbarri | Wernberg et al. (2016a)|
| Thermal performance of Ecklonia radiata | Wernberg et al. (2016b) and Britton et al. (2024) |
| Occurrence distribution of Ecklonia radiata | Ocean Biodiversity Information System (OBIS). Data access from https://github.com/iobis/robis |
| Sea surface temperature | High Resolution NOAA Optimum Interpolation 1/4 Degree Daily SST (OISST) Analysis, Version 2.1 (Huang et al. 2021) https://www.ncei.noaa.gov/metadata/geoportal/rest/metadata/item/gov.noaa.ncdc:C00844/html |
| Subsurface ocean temperature | Bluelink Ocean Reanalysis (BRAN2020) avaliable at available at https://doi.org/10.25914/6009627c7af03 (Chamberlain et al. 2021) |


## Data files
| File | Description |
|-----:|---------------|
| `4pop_change_rawdata.csv` | Dataset of the change in canopy cover of *Ecklonia radiata* for the four locations, including the corresponding MHW metrics, including columns of study locations, sites, survey years, species name, kelp cover percentages, absolute kelp cover change, and corresponding summer temperature and MHW metrics (Output of `mhw_kelp_detection.ipynb` and `mhw_kelp_kalbarri_detection.ipynb`)|
| `OBIS_ER_distribution.csv` | Dataset of the Ecklonia radiata distribution and occurrence from OBIS, which were regrided into 1/4 degree to match the spatial resolution of OISST, including the location coordinates and the occurrence frequency  (Output of `model_4pop.ipynb`)|
| `dhdmodel_change_relationship.csv` | Modelling results of the change in canopy cover of *Ecklonia radiata* and cumulative intensity for the four locations  (Output of `mhw_kelp_detection.ipynb` and `mhw_kelp_kalbarri_detection.ipynb`)|
| `dtdtmodel_change_relationship.csv` | Modelling results of the change in canopy cover of *Ecklonia radiata* and temperature tendency for the four locations  (Output of `mhw_kelp_detection.ipynb` and `mhw_kelp_kalbarri_detection.ipynb`)|
| `er_3pop_site.csv` | Dataset of *Ecklonia radiata* averaged at site level in Jurien, Jervis Bay, and Maria Island (Output of `clean_kelp_data_surveyid.R`)|
| `er_atrc_id.csv` | Dataset of *Ecklonia radiata* at survey_id level after quality control. The identical survey_id represents a survey conducted on the same transect. (Output of `clean_kelp_data_surveyid.R`) |
| `er_atrc_site.csv` | Dataset of *Ecklonia radiata* at site level after quality control. (Output of `clean_kelp_data_surveyid.R`) |
| `inten_max_model_change_relationship.csv` | Modelling results of the change in canopy cover of *Ecklonia radiata* and maximum intensity for the four locations  (Output of `mhw_kelp_detection.ipynb` and `mhw_kelp_kalbarri_detection.ipynb`)|
| `kalbarri_abundance.csv` | Dataset of the location-averaged *Ecklonia radiata* canopy cover in Kalbarri extracted from Wernberg et al. (2016a) |
| `model_change_relationship.csv` | Modelling results of the change in canopy cover of *Ecklonia radiata* and absolute temperature for the four locations  (Output of `mhw_kelp_detection.ipynb` and `mhw_kelp_kalbarri_detection.ipynb`)|
| `dtdtmodel_change_relationship.csv` | Modelling results of the change in canopy cover of *Ecklonia radiata* and temperature tendency for the four locations  (Output of `mhw_kelp_detection.ipynb` and `mhw_kelp_kalbarri_detection.ipynb`)|
| `populations_TPC.csv` | Thermal performance data from experiments by Wernberg et al. (2016) and Britton et al. (2024), including locations, coordinates, temperature, and species response (net photosynthesis) |


## Code files
| File | Description |
|-----:|---------------|
| `clean_kelp_data_survey_id.R` | Fixing the recording-only-presence problem of the raw kelp cover data, and averaging the data into survey_id and site level |
| `mhw_kelp_detection.ipynb` | Calculating summer time temperature and MHW metrics for each site and year of kelp surveys, conducting GLMM analysis |
| `mhw_kelp_kalbarri_detection.ipynb` | Calculating summer time temperature and MHW metrics for the location-averaged kelp surveys in Kalbarri (Wernberg et al. 2016a), conducting GLM analysis |
| `mhw_kelp_timeseries.ipynb` | Plotting timeseries of summer-time temperature, annual abundance of kelp, and MHW categories. |
| `model_4pop.ipynb` | Calculating the SST seasonal climatology for each OBIS location of Ecklonia; Figure 2 is produced in the last cell. |
| `downsample_sensitivity_test.ipynb` | Sensitivity test of the GLMM regression for kelp change slope patterns across locations by downsampling data |
| `tpc_review.R` | Constructing thermal performance curve and temperature limits for 4 locations from Wernberg et al. (2016) and Britton et al. (2024). Figure 3 is produced at line 274. |

### Note
Several analyses are implemented as Jupyter notebooks (`.ipynb`). To run these notebooks:

1. Ensure Python (≥3.9) is installed.
2. Install required packages (e.g. via conda or pip)
3. Launch Jupyter, and open the desired `.ipynb` file and run cells sequentially from top to bottom.

# References
Britton, D, Layton, C, Mundy, CN, Brewer, EA, Gaitan-Espitia, JD, Beardall, J, Raven, JA & Hurd, CL 2024, 'Cool-edge populations of the kelp Ecklonia radiata under global ocean change scenarios: strong sensitivity to ocean warming but little effect of ocean acidification', Proc Biol Sci, vol. 291, no. 2015, p. 20232253.

Chamberlain, M. A., Oke, P. R., Fiedler, R. A. S., Beggs, H. M., Brassington, G. B., & Divakaran, P. (2021). Next generation of Bluelink ocean reanalysis with multiscale data assimilation: BRAN2020. Earth Syst. Sci. Data, 13(12), 5663-5688.

Huang, B., Liu, C., Banzon, V., Freeman, E., Graham, G., Hankins, B., Smith, T., & Zhang, H.-M. (2021). Improvements of the Daily Optimum Interpolation Sea Surface Temperature (DOISST) Version 2.1. Journal of Climate, 34(8), 2923-2939. 

Reef Life Survey (RLS); Institute for Marine and Antarctic Studies (IMAS); Parks Victoria; Department of Primary Industries (DPI), New South Wales Government; Parks and Wildlife Tasmania; Department for Environment and Water (DEWNR), South Australia; Department of Biodiversity, Conservation and Attractions (DBCA), Western Australia; Integrated Marine Observing System (IMOS), 2024, IMOS - National Reef Monitoring Network Sub-Facility – Benthic cover data (in situ surveys), database provided, 10/10/2024.

Wernberg, T, Bennett, S, Babcock, RC, Bettignies, Td, Cure, K, Depczynski, M et al. 2016a. Climate-driven regime shift of a temperate marine ecosystem. Science, 353, 169-172.

Wernberg, T, de Bettignies, T, Joy, BA & Finnegan, PM 2016b, 'Physiological responses of habitat‐forming seaweeds to increasing temperatures', Limnology and Oceanography, vol. 61, no. 6, pp. 2180-2190.
