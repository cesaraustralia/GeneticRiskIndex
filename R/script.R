source("common.R")
source("prefilter.R")
source("observations.R")
source("resistance.R")
source("distance.R")

datapath <- "../../data"
ala_email <- "rafaelschouten@gmail.com"
ala_config(email=ala_email)

# Taxa prefiltering constants
# TODO: make this a dict to pass to prefilter_taxa() ?
MAXCOUNT <- 10000
MINCOUNT <- 50
MINPROPINSTATE <- 0.1
HABITAT_RASTER <- "habitat.asc"
HABITAT_RASTER_PATH <- file.path(datapath, HABITAT_RASTER)

# Observation prefiltering constants
STATE <- "Victoria"
TIMESPAN <- c(1960:2021)
BASIS <- "HumanObservation"

mask_layer <- terra::rast(HABITAT_RASTER_PATH) < 0
terra::crs(mask_layer) <- as.character(sp::CRS(paste0("+init=epsg:", METRIC_EPSG)))
taxa_csv <- file.path(datapath, "taxa.csv")
taxa <- read.csv(taxa_csv, header = TRUE)

# Categorize risk using queries to ALA: slow.
categorized_taxa <- precategorize_risk(taxa)

# Split data with local queries
filtered_taxa <- filter(categorized_taxa, risk != "unknown")
remaining_taxa <- filter(categorized_taxa, risk == "unknown")

# Filter if can assess currently
assesible_taxa <- filter(remaining_taxa, assess == "ALA", taxon_level == "Base")
unassessed_taxa <- filter(remaining_taxa, assess != "ALA", taxon_level != "Base")

# Split assessable into Habitat and Distance groups
habitat_taxa <- filter(assesible_taxa, disperse_model == "Habitat")
distance_taxa <- filter(assesible_taxa, disperse_model == "Distance")

write_csv(filtered_taxa, file.path(datapath, "filtered.csv"))
if (nrow(unassessed_taxa) > 0) {
  write_csv(unnassessed_taxa, file.path(datapath, "unnaccessed_taxa.csv"))
}
write_csv(distance_taxa, file.path(datapath, "distance.csv"))
write_csv(habitat_taxa, file.path(datapath, "habitat.csv"))

# Get observation data, cluster, and write to csv and raster
cluster_observations(remaining_taxa, mask_layer, datapath)

# Download and write raster files for resistance models
prepare_resistance_files(habitat_taxa, datapath)

# Manual methods fot testing

# taxon <- head(taxa, 1)
# obs <- get_observations(taxon$ALA.taxon)
# filtered <- prefilter_obs(obs)
# fn <- process_obs(filtered, taxon, mask_layer, path)
# fn %>% terra::rast() %>% plot

# find_field_values("species")
