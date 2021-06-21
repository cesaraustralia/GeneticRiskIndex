source("common.R")
source("prefilter.R")
source("observations.R")
source("resistance.R")
source("distance.R")
source("fire_severity.R")

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


# Precategorize based on counts
# Categorize risk using queries to ALA: slow.
categorized_taxa <- precategorize_risk(taxa)

# Taxa we have already assigned risk to in prefiltering
filtered_taxa <- filter(categorized_taxa, risk != "unknown")
write_csv(filtered_taxa, file.path(groupingspath, "filtered_taxa.csv"))

# Taxa we can't assess currently
unassessed_taxa <- filter(categorized_taxa, risk == "unknown", assess != "ALA")
head(unassessed_taxa)
write_csv(unassessed_taxa, file.path(groupingspath, "unassessed_taxa.csv"))

# Taxa we can assess
assesible_taxa <- filter(categorized_taxa, risk == "unknown", assess == "ALA")

# Taxa to access based on distance metrics
distance_taxa <- filter(assesible_taxa, disperse_model == "Distance")
head(distance_taxa)
nrow(distance_taxa)
write_csv(distance_taxa, file.path(groupingspath, "distance_taxa.csv"))

# Taxa to access with Circuitscape resistance models
resistance_taxa <- filter(assesible_taxa, disperse_model == "Habitat")
head(resistance_taxa)
nrow(resistance_taxa)
write_csv(resistance_taxa, file.path(groupingspath, "all_resistance_taxa.csv"))

# Manual single taxon observations and clusering for testing:
taxon <- failed_resistance_taxa[5, ] 
process_observations(taxon, mask_layer, taxapath, error=TRUE)


# load/download, filter and cluster observations for all taxa
clustered_taxa <- process_observations(resistance_taxa, mask_layer, taxapath)
head(clustered_taxa)
nrow(clustered_taxa)

# Taxa that failed clustering for some reason or other 
failed_resistance_taxa <- filter(clustered_taxa, risk == "failed")
head(failed_resistance_taxa)
nrow(failed_resistance_taxa)
failed_resistance_taxa$error
failed_resistance_taxa$ala_search_term
write_csv(failed_resistance_taxa, file.path(groupingspath, "failed_resistance_taxa.csv"))
process_observations(failed_resistance_taxa, mask_layer, taxapath)

# Taxa that we don't need to process - these have a lot of clusters
many_clustered_taxa <- filter(clustered_taxa, num_clusters >= MAX_CLUSTERS, risk != "failed")
head(many_clustered_taxa)
write_csv(many_clustered_taxa, file.path(groupingspath, "many_clustered_taxa.csv"))

# Taxa that we need to process with circuitscape
circuitscape_taxa <- filter(clustered_taxa, num_clusters < MAX_CLUSTERS, risk != "failed")
head(circuitscape_taxa)
nrow(circuitscape_taxa)
write_csv(circuitscape_taxa, file.path(groupingspath, "circuitscape_taxa.csv"))

# Download and write raster files for circuitscape resistance models
if (nrow(circuitscape_taxa) > 0) {
  prepare_resistance_files(circuitscape_taxa, taxapath)
}
