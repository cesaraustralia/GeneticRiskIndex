library(galah)
library(fasterize)
library(fpc)
library(lubridate)
library(sf)
library(terra)
library(tidyverse) # includes dplyr & readr

# metric reference system epsg code
METRIC_EPSG <- 3111
# lat/lon reference system epsg code
LATLON_EPSG <- 4326

# Galah doesn't seem to handle more than about 1000 rows
# So 800 is a conservative estimate
GALAH_MAXROWS <- 800
