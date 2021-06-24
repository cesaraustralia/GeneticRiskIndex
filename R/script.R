source("common.R")
source("prefilter.R")
source("observations.R")
source("resistance.R")
source("distance.R")
source("fire_severity.R")

# In case downloads run out of time
options(timeout=500)
datapath <- file.path(path_home(), "data")
taxapath <- file.path(datapath, "taxa")
groupingspath <- file.path(datapath, "groupings")
dir.create(taxapath, recursive = TRUE)
dir.create(groupingspath, recursive = TRUE)
ala_email <- "rafaelschouten@gmail.com"
ala_config(email=ala_email)

# Taxa prefiltering constants
# TODO: make this a dict to pass to prefilter_taxa() ?
MAXCOUNT <- 10000
MINCOUNT <- 50
MAX_CLUSTERS <- 80
MIN_CLUSTERS <- 1

MINPROPINSTATE <- 0.1
HABITAT_RASTER <- "sbv.tif"
HABITAT_RASTER_PATH <- file.path(datapath, HABITAT_RASTER)
RESISTANCE_RASTER <- "resistance.tif"
FIRE_SEVERITY_RASTER_PATH <- file.path(datapath, "fire_severity.tif")
TAXA_CSV_PATH <- file.path(datapath, "taxa.csv")

FIRE_SEVERITY_RASTER_URL = "https://genetic-risk-index-bucket.s3.ap-southeast-2.amazonaws.com/fire_severity.tif"
HABITAT_RASTER_URL = "https://genetic-risk-index-bucket.s3.ap-southeast-2.amazonaws.com/sbv.tif"
TAXA_URL = "https://genetic-risk-index-bucket.s3.ap-southeast-2.amazonaws.com/taxa.csv"

# Download
maybe_download(FIRE_SEVERITY_RASTER_URL, FIRE_SEVERITY_RASTER_PATH)
maybe_download(HABITAT_RASTER_URL, HABITAT_RASTER_PATH)
maybe_download(TAXA_URL, TAXA_CSV_PATH)

# Plot rasters
# HABITAT_RASTER_PATH %>% terra::rast() %>% plot
# FIRE_SEVERITY_RASTER_PATH %>% terra::rast() %>% plot

# Observation prefiltering constants
STATE <- "Victoria"
TIMESPAN <- c(1960:2021)
BASIS <- "HumanObservation"

mask_layer <- terra::rast(HABITAT_RASTER_PATH) < 0
terra::crs(mask_layer) < as.character(sp::CRS(paste0("+init=epsg:", METRIC_EPSG)))
# plot(mask_layer)

# Load main taxa dataframe from csv
taxa <- read.csv(TAXA_CSV_PATH, header = TRUE)
head(taxa)


####################################################################################
# Precategorize based on counts
# Categorize risk using queries to ALA: slow.
precategorized_taxa <- precategorize_risk(taxa)
head(precategorized_taxa)
precategorized_taxa$filter_category

# Taxa to access based on distance metrics
write_csv(precategorized_taxa, file.path(groupingspath, "precategorized_taxa.csv"))

# Manual single taxon observations and preclusering for testing:
# taxon <- failed_resistance_taxa[5, ]
# process_observations(taxon, mask_layer, taxapath, error=TRUE)


####################################################################################
# Clustering for Isolatrion by distance and resistance taxa

isolation_taxa <- filter(precategorized_taxa, filter_category %in% c("isolation_by_distance", "isolation_by_resistance"))
nrow(isolation_taxa)
head(isolation_taxa)

# load/download, filter and precluster observations for all taxa
preclustered_isolation_taxa <- process_observations(isolation_taxa, mask_layer, taxapath, error=TRUE)
head(preclustered_isolation_taxa)
nrow(preclustered_isolation_taxa)

####################################################################################
# Main CSV output

# Write csv for all catagorized taxa
categorized_taxa <- left_join(precategorized_taxa, preclustered_isolation_taxa, by="ala_search_term")
write_csv(categorized_taxa, file.path(groupingspath, "catagorized_taxa.csv"))
head(categorized_taxa)
categorized_taxa$error


####################################################################################
# Circuitscape/isolation by resistance output

# Write csv for taxa that we need to process with circuitscape
isolation_by_resistance_taxa <- filter(preclustered_isolation_taxa, num_preclusters < MAX_CLUSTERS, filter_category != "failed")
head(isolation_by_resistance_taxa)
nrow(isolation_by_resistance_taxa)
isolation_by_resistance_taxa$error
write_csv(isolation_by_resistance_taxa, file.path(groupingspath, "isolation_by_resistance_taxa.csv"))

# Download and write raster files for circuitscape resistance models
if (nrow(isolation_by_resistance_taxa) > 0) {
  prepare_resistance_files(isolation_by_resistance_taxa, taxapath)
}
