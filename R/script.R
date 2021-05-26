path <- "../data"
taxon_csv <- "../../DELWPshort.csv"
mask_layer <- terra::rast("../data/sbv.tif")
mask_layer <- mask_layer < 0
terra::crs(mask_layer) <- as.character(sp::CRS(paste0("+init=epsg:", METRIC_EPSG)))
plot(mask_layer)

taxon_params <- read.csv(taxon_csv, header = TRUE)
taxonids <- sp_params$Taxon.Id

for (taxonid in taxonids) {
  process_taxon(sp_params, taxonid, mask_layer, path)
}

# taxonid <- 13029
# taxon <- dplyr::filter(params, Taxon.Id == taxonid)
# obs <- load_species_observations(taxon$ALA.taxon) %>%
#   drop_na(any_of(c("decimalLatitude", "decimalLongitude")))
# obs_to_rasters(obs, params, eps, mask_layer, path)
# asc <- terra::rast("/home/raf/13029_clusters.asc")
# plot(asc)

# obs <- ala_occurrences(
#   taxa = select_taxa(sp$ALA.taxon),
#   filters = select_filters(
#     year = c(1960:2021), 
#     basisOfRecord = "Human Observaion",
#     stateProvince = "Victoria"
#   )
# )
