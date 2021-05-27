source("common.R")
source("prefilter.R")
source("download_hdm.R")
source("observations.R")

ala_config(email="rafaelschouten@gmail.com")
path <- "/home/raf/Work/cesar/risk/GeneticRiskIndex/data"

# Taxa prefiltering constants
# TODO: make this a dict to pass to prefilter_taxa() ?
MAXCOUNT <- 10000
MINCOUNT <- 50
MINPROPINSTATE  <- 0.1

# Observation prefiltering constants
STATE <- "Victoria"
TIMESPAN <- c(1960:2021)
BASIS <- "HumanObservation"

mask_layer <- terra::rast("../data/sbv.tif") < 0
terra::crs(mask_layer) <- as.character(sp::CRS(paste0("+init=epsg:", METRIC_EPSG)))
taxa_csv <- "../../DELWPshort.csv"
# taxa_csv <- "../../DELWPmedium.csv"
# taxa_csv <- "../../DELWPfull.csv"
taxa <- read.csv(taxa_csv, header = TRUE)
taxa$DELWP.common.name

categorized_taxa <- precategorize_risk(taxa)
filtered_taxa <- filter(categorized_taxa, risk != "unknown")
remaining_taxa <- filter(categorized_taxa, risk == "unknown") %>%
  cluster_taxa(mask_layer, path)
habitat_taxa <- filter(remaining_taxa, Disperse.model == "Habitat")
distance_taxa <- filter(remaining_taxa, Disperse.model == "Distance") %>%
  categorize_by_distance(path)

write_csv(filtered_taxa, "filtered.csv")
write_csv(distance_taxa, "distance")
write_csv(habitat_taxa, "habitat.csv")

prepare_resistance_files(habitat_taxa, path)


# Manual methods fot testing

taxon <- head(taxa, 1)
obs <- get_observations(taxon$ALA.taxon)
filtered <- prefilter_obs(obs)
fn <- process_obs(filtered, taxon, mask_layer, path)
fn %>% terra::rast() %>% plot

# find_field_values("species")
