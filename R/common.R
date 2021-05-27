library(sf)
library(galah)
library(fpc)
library(terra)
library(fasterize)
library(sf)
library(tidyverse) # includes dplyr & readr
library(lubridate)

# metric reference system epsg code
METRIC_EPSG <- 3111
# lat/lon reference system epsg code
LATLON_EPSG <- 4326

# Generic data filter for galah
FILTERS <- select_filters(
  year = c(1960:2021), 
  basis_of_record = "HumanObservation",
  stateProvince = "Victoria"
)
