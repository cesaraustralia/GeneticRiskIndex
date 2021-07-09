library(galah)
library(fpc)
library(lubridate)
library(sf)
library(terra)
library(tidyverse) # includes dplyr & readr
library(fs)
library(RcppTOML)

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
  underscored <- gsub(" ", "_", taxon$ala_search_term)[[1]]
  taxonpath <- file.path(taxapath, underscored)
  # Create the directory if it doesn't exist yet
  dir.create(taxonpath, recursive = TRUE)
  return(taxonpath)
}

# Download from a URL if the file doesn't exist allready
maybe_download <- function(url, path) {
  if (!file.exists(path)) {
    download.file(url, path)
  }
}

# Run parameters ######################################################################

# Primary path for all input data
datapath <- file.path(path_home(), "data")

# Paths to files and folders #########################################################
taxapath <- file.path(datapath, "taxa")
groupingspath <- file.path(datapath, "groupings")
dir.create(taxapath, recursive = TRUE)
dir.create(groupingspath, recursive = TRUE)

HABITAT_RASTER <- "habitat.tif"
HABITAT_RASTER_PATH <- file.path(datapath, HABITAT_RASTER)

FIRE_SEVERITY_RASTER <- "fire_severity.tif"
FIRE_SEVERITY_RASTER_PATH <- file.path(datapath, FIRE_SEVERITY_RASTER)

BATCH_TAXA_CSV <- "batch_taxa.csv"
BATCH_TAXA_CSV_PATH <- file.path(datapath, BATCH_TAXA_CSV)

RESISTANCE_RASTER <- "resistance.tif"

CONFIG_FILE <- "config.toml"
CONFIG_PATH <- file.path(datapath, CONFIG_FILE)

# Download from s3 bucket if it is passed as a command line argument
args = commandArgs(trailingOnly=TRUE)
if (length(args) > 0) {
  bucket_url <- paste0(args[1], "/")
  batch_taxa_url <- paste0(bucket_url, BATCH_TAXA_CSV)
  config_url <- paste0(bucket_url, CONFIG_FILE)
  habitat_raster_url <- paste0(bucket_url, HABITAT_RASTER)
  fire_severity_raster_url <- paste0(bucket_url, FIRE_SEVERITY_RASTER)

  # Download
  maybe_download(fire_severity_raster_url, FIRE_SEVERITY_RASTER_PATH)
  maybe_download(habitat_raster_url, HABITAT_RASTER_PATH)
  # If we are on aws batch, always download updated taxa and config
  if (Sys.getenv("AWS_BATCH_CE_NAME") != "") {
    download.file(batch_taxa_url, BATCH_TAXA_CSV_PATH)
    download.file(config_url, CONFIG_PATH)
  } else {
    maybe_download(batch_taxa_url, BATCH_TAXA_CSV_PATH)
    maybe_download(config_url, CONFIG_PATH)
  }
}

# Get config variables from the toml file
list2env(parseTOML(file.path(datapath, CONFIG_FILE)), globalenv())
# Define timespan
TIMESPAN <- c(TIME_START:TIME_END)
# ALA needs an email address for some reason
ala_config(email=ALA_EMAIL)
# In case downloads run out of time
options(timeout=500)

# Plot rasters
# HABITAT_RASTER_PATH %>% terra::rast() %>% plot
# FIRE_SEVERITY_RASTER_PATH %>% terra::rast() %>% plot

mask_layer <- terra::rast(HABITAT_RASTER_PATH) < 0
terra::crs(mask_layer) < as.character(sp::CRS(paste0("+init=epsg:", METRIC_EPSG)))
# plot(mask_layer)
