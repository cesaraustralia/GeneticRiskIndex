library(galah)
library(fasterize)
library(fpc)
library(lubridate)
library(sf)
library(terra)
library(tidyverse) # includes dplyr & readr
library(fs)

# metric reference system epsg code
METRIC_EPSG <- 3111
# lat/lon reference system epsg code
LATLON_EPSG <- 4326

# Galah doesn't seem to handle more than about 1000 rows
# So 800 is a conservative estimate
GALAH_MAXROWS <- 800

# Get the directory path for files relating to a specific taxon
taxon_path <- function(taxon, taxapath) {
  # We use underscores in the directory name
  underscored <- gsub(" ", "_", taxon$delwp_taxon)[[1]]
  taxonpath <- file.path(taxapath, underscored)
  # Create the directory if it doesn't exist yet
  dir.create(taxonpath, recursive = TRUE)
  return(taxonpath)
}

maybe_download <- function(url, path) {
  if (!file.exists(path)) {
    download.file(url, path)
  }
}
