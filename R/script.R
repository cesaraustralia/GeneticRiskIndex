source("functions.R")
path <- "../data"
taxon_csv <- "../../DELWPshort.csv"
mask_layer <- terra::rast("../data/sbv.tif")
mask_layer <- mask_layer < 0
terra::crs(mask_layer) <- as.character(sp::CRS(paste0("+init=epsg:", METRIC_EPSG)))

taxon_params <- read.csv(taxon_csv, header = TRUE)
taxonids <- taxon_params$Taxon.Id

for (taxonid in taxonids) {
  process_taxon(taxon_params, taxonid, mask_layer, path)
}
