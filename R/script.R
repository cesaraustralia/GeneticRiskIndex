source("common.R")
source("prefilter.R")
source("observations.R")
source("resistance.R")
source("distance.R")
source("fire_severity.R")

datapath <- file.path(path_home(), "data")
taxapath <- file.path(datapath, "taxa")
dir.create(taxapath)
ala_email <- "rafaelschouten@gmail.com"
ala_config(email=ala_email)

# Taxa prefiltering constants
# TODO: make this a dict to pass to prefilter_taxa() ?
MAXCOUNT <- 10000
MINCOUNT <- 50
MINPROPINSTATE <- 0.1
RESISTANCE_RASTER <- "sbv.tif"
RESISTANCE_RASTER_PATH <- file.path(datapath, RESISTANCE_RASTER)
FIRE_SEVERITY_RASTER_PATH <- file.path(datapath, "fire_severity.tif")

RESISTANCE_RASTER_PATH %>% terra::rast() %>% plot
FIRE_SEVERITY_RASTER_PATH %>% terra::rast() %>% plot

# Observation prefiltering constants
STATE <- "Victoria"
TIMESPAN <- c(1960:2021)
BASIS <- "HumanObservation"

mask_layer <- terra::rast(RESISTANCE_RASTER_PATH) < 0
terra::crs(mask_layer) <- as.character(sp::CRS(paste0("+init=epsg:", METRIC_EPSG)))
plot(mask_layer)

taxa_csv <- file.path(datapath, "taxa.csv")
taxa <- read.csv(taxa_csv, header = TRUE)

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

write_csv(filtered_taxa, file.path(datapath, "filtered.csv"))
if (nrow(unassessed_taxa) > 0) {
  write_csv(unnassessed_taxa, file.path(datapath, "unnaccessed_taxa.csv"))
}
write_csv(distance_taxa, file.path(datapath, "distance.csv"))
write_csv(resistance_taxa, file.path(datapath, "resistance"))

process_observations(head(remaining_taxa, 3), mask_layer, taxapath)

# Download and write raster files for resistance models
prepare_resistance_files(resistance_taxa, taxapath)

# Manual step-by-step methods for testing
# taxon <- head(taxa, 1)

# Enter an ALA search term
taxon <- filter(taxa, ala_search_term == "Crinia parinsignifera")
# Or a number 
taxon <- remaining_taxa[10,]
# Get observations
obs <- load_or_dowload_obs(taxon, taxapath)
head(obs)
# Filter
filtered <- filter_observations(obs, taxon)
head(filtered)
# Cluster
clustered <- cluster_observations(obs, taxon)
head(clustered)
# Write and view rasters
fn <- write_cluster_rasters(clustered, taxon, mask_layer, taxapath)
fn[1] %>% terra::rast() %>% plot
fn[2] %>% terra::rast() %>% plot
