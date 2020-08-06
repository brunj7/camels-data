# CAMELS data processing

Processing of NCAR Catchement Attributes and Meteorlogy for Large-sample Studies (CAMELS) data using R

https://ral.ucar.edu/solutions/products/camels

## More about this data set

671 small - medium size catchments over the contiguous US (CONUS) minimally impacted by human activities.

2 main type of daily time-series:

- Daily atmospheric forcing (source: Daymet, Maurer and NLDAS)
- Hydrologic reponse (source: USGS daily streamflow)

Attributes data (climatologies):

- topography
- climate
- streamflow
- land cover
- soil
- geology


## R package `CamelsQuery`

We developped an R package [`CamelsQuery`](https://github.com/brunj7/CamelsQuery) to ease the query of the CAMELS data using HUC8 identifier of the basins / streamgauges. With also added wrapper functions around the `dataRetrieval package` from USGS to query for chemistry data.





code creating the data: https://github.com/naddor/camels
