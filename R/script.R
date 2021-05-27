source("common.R")
source("prefilter.R")
source("observations.R")

ala_config(email="@gmail.com")

# Prefiltering constants
# TODO: make this a dict to pass to prefilter_taxa() ?
MAXCOUNT <- 10000
MINCOUNT <- 50
MINPROPINSTATE  <- 0.1

path <- "../data"
mask_layer <- terra::rast("../data/sbv.tif") < 0
terra::crs(mask_layer) <- as.character(sp::CRS(paste0("+init=epsg:", METRIC_EPSG)))
taxa_csv <- "../../DELWPshort.csv"
# taxa_csv <- "../../DELWPmedium.csv"
# taxa_csv <- "../../DELWPfull.csv"
taxa <- read.csv(taxa_csv, header = TRUE)

ftaxa <- prefilter_taxa(taxa)
ftaxa$state_count

for (taxonid in ftaxa$Taxon.Id) {
  process_taxon(ftaxa, taxonid, mask_layer, path)
}

# obs = get_observations(taxon$ALA.taxon)
# find_field_values("species")
