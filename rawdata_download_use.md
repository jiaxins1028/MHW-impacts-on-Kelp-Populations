## Downloading Raw Species and Temperature Data

These instructions explain exactly how to obtain the raw data and where to place them.

🌱 1. Kelp Cover Survey Data from Australian National Reef Monitoring Network

Source:
https://catalogue-imos.aodn.org.au/geonetwork/srv/eng/catalog.search#/metadata/ec424e4f-0f55-41a5-a3f2-726bc4541947

Download the data through the link above, and save files into: `er_atrc.csv`.

Files used in: `clean_kelp_data_surveyid.R`


🐚 2. OBIS Occurrence Data for Ecklonia radiata

Downloaded via robis R package (https://github.com/iobis/robis) or go to the link above and search *Ecklonia radiata*

Save file into: `ER_OBIS.csv`.

Files used in: `model_4pop.ipynb`.


🌡 3. Sea Surface Temperature (SST) – NOAA OISST v2.1

Source: https://www.ncei.noaa.gov/metadata/geoportal/rest/metadata/item/gov.noaa.ncdc:C00844/html

Download via the link above and subset dataset to the focal region and time window.

```
idx_reg = {'W': 100, 'E': 160, 'S': -50, 'N': -20 }
source = '/oisst/data/yearly/'

# combine required oisst
for i in range(1981, 2025):
    infile = source + 'oisst-avhrr-v02r01_'+ str(i) + '.nc'
    ds = xr.open_dataset(infile)
    f = ds['sst']
    
    fregion = f.sel(lat=slice(idx_reg['S'], idx_reg['N']), lon=slice(idx_reg['W'], idx_reg['E']))
    fregion.to_netcdf(path = 'OBIS_kelp_'+ str(i) + '.nc')
    
# combine yearly sst into one nc file
infile = 'OBIS_kelp_*'

ds = xr.open_mfdataset(infile).sortby('time').compute()
ds.to_netcdf(path = 'OBIS_kelp_sst.nc')
```

Files used in: `mhw_kelp_timeseries.ipynb`, `model_4pop.ipynb`, `mhw_kelp_detection.ipynb`, `mhw_kelp_kalbarri_detection.ipynb`

