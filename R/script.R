source("common.R")
source("prefilter.R")
source("observations.R")
source("resistance.R")
source("distance.R")
source("fire_severity.R")

datapath <- file.path(path_home(), "data")
taxapath <- file.path(datapath, "taxa")
groupingspath <- file.path(datapath, "groupings")
dir.create(taxapath)
dir.create(groupingspath)
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
RESISTANCE_RASTER_PATH <- file.path(datapath, RESISTANCE_RASTER)
FIRE_SEVERITY_RASTER_PATH <- file.path(datapath, "fire_severity.tif")
TAXA_CSV_PATH <- file.path(datapath, "taxa.csv")

FIRE_SEVERITY_RASTER_URL = "https://genetic-risk-index-bucket.s3.ap-southeast-2.amazonaws.com/fire_severity.tif"
HABITAT_RASTER_URL = "https://genetic-risk-index-bucket.s3.ap-southeast-2.amazonaws.com/sbv.tif"
TAXA_URL = "https://genetic-risk-index-bucket.s3.ap-southeast-2.amazonaws.com/taxa.csv"

# Download
maybe_download(FIRE_SEVERITY_RASTER_URL, FIRE_SEVERITY_RASTER_PATH)
maybe_download(HABITAT_RASTER_URL, HABITAT_RASTER_PATH)
maybe_download(TAXA_URL, TAXA_CSV_PATH)

# Convert habitat to resistance
habitat_to_resistance(HABITAT_RASTER_PATH, RESISTANCE_RASTER_PATH)

# Plot rasters
# HABITAT_RASTER_PATH %>% terra::rast() %>% plot
# RESISTANCE_RASTER_PATH %>% terra::rast() %>% plot
# FIRE_SEVERITY_RASTER_PATH %>% terra::rast() %>% plot

# Observation prefiltering constants
STATE <- "Victoria"
TIMESPAN <- c(1960:2021)
BASIS <- "HumanObservation"

mask_layer <- terra::rast(RESISTANCE_RASTER_PATH) < 0
terra::crs(mask_layer) <- as.character(sp::CRS(paste0("+init=epsg:", METRIC_EPSG)))
# plot(mask_layer)

# Load main taxa dataframe from csv
taxa <- read.csv(TAXA_CSV_PATH, header = TRUE)


# Precategorize based on counts

# Categorize risk using queries to ALA: slow.
categorized_taxa <- precategorize_risk(taxa)

# Split data with local queries
filtered_taxa <- filter(categorized_taxa, risk != "unknown")
remaining_taxa <- filter(categorized_taxa, risk == "unknown")

# Filter if we can assess currently
assesible_taxa <- filter(remaining_taxa, assess == "ALA", taxon_level == "Base")
unassessed_taxa <- filter(remaining_taxa, assess != "ALA", taxon_level != "Base")

# Split assessable into Habitat and Distance groups
resistance_taxa <- filter(assesible_taxa, disperse_model == "Habitat")
distance_taxa <- filter(assesible_taxa, disperse_model == "Distance")

write_csv(filtered_taxa, file.path(groupingspath, "filtered_taxa.csv"))
if (nrow(unassessed_taxa) > 0) {
  write_csv(unassessed_taxa, file.path(groupingspath, "unassessed_taxa.csv"))
}
write_csv(distance_taxa, file.path(groupingspath, "distance.csv"))
write_csv(resistance_taxa, file.path(groupingspath, "resistance.csv"))

# Manual single taxon observations and clusering for testing:

# taxon <- remaining_taxa[i, ] 
# obs <- load_or_dowload_obs(taxon, taxapath)
# head(obs)
# filtered <- filter_observations(obs, taxon)
# head(filtered)
# clustered <- cluster_observations(obs, taxon)
# head(clustered)
# fn <- write_cluster_rasters(clustered, taxon, mask_layer, taxapath)
# fn[1] %>% terra::rast() %>% plot
# fn[2] %>% terra::rast() %>% plot

# Automated: process observations for all taxa
clustered_taxa <- process_observations(resistance_taxa, mask_layer, taxapath)

failed_resistance_taxa <- filter(clustered_taxa, risk == "failed")
failed_resistance_taxa$ala_search_term
common_resistance_taxa <- filter(clustered_taxa, num_clusters >= MAX_CLUSTERS, risk != "failed")
rare_resistance_taxa <- filter(clustered_taxa, num_clusters < MAX_CLUSTERS, risk != "failed")

write_csv(failed_resistance_taxa, file.path(groupingspath, "failed_resistance_taxa"))
write_csv(common_resistance_taxa, file.path(groupingspath, "common_resistance_taxa.csv"))
write_csv(rare_resistance_taxa, file.path(groupingspath, "rare_resistance_taxa.csv"))

# Download and write raster files for resistance models
prepare_resistance_files(rare_resistance_taxa, taxapath)
