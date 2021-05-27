# Retrieving observation data from ALA ######################################################

# Get taxon observations from ALA using `galah`
get_observations <- function(taxon) {
  print(paste0("  Retrieving observations from ALA for ", taxon))
  obs <- ala_occurrences(
    taxa = select_taxa(taxon),
    filters = FILTERS,
  )
  return(obs)
}


# Manipulating observation data ######################################################

# Add transformed coordinates "x" an "y" for accurate distance calculations
add_euclidan_coords <- function(obs) {
    sf::st_as_sf(obs, coords = c("decimalLongitude", "decimalLatitude"), crs = LATLON_EPSG) %>% 
    sf::st_transform(crs = METRIC_EPSG) %>% 
    mutate(x = sf::st_coordinates(.)[,1],
           y = sf::st_coordinates(.)[,2]) %>% 
    sf::st_drop_geometry()
}

# Scan clusters and add cluster index to observations
add_clusters <- function(obs, eps) {
  clusters <- fpc::dbscan(obs[, c("x", "y")], eps = eps * 1000, MinPts = 3)
  out <- mutate(obs, clusters = clusters$cluster)
  return(out)
}

# Add buffer arond clusters
buffer_clustered <- function(geoms, eps) {
  dplyr::filter(geoms, clusters != 0) %>% 
    st_buffer(dist = eps * 1000) %>% 
    st_union()
}

# Add buffer arond orphans
buffer_orphans <- function(geoms, eps) {
  dplyr::filter(geoms, clusters == 0) %>% 
    st_buffer(dist = eps * 1000) %>% 
    st_union()
}

# Write the clustered and orphan observations to raster files
write_rasters <- function(obs, eps, mask_layer, path) {
  geoms <- sf::st_as_sf(obs, coords = c("x", "y"), crs = METRIC_EPSG)
  clustered <- buffer_clustered(geoms, eps)
  orphans <- buffer_orphans(geoms, eps)
  if(!is.null(nrow(clustered))){
    geom_to_raster(clustered, "clusters", mask_layer, path)
  }
  if(!is.null(nrow(orphans))){
    geom_to_raster(orphans, "orphans", mask_layer, path)
  }
}

# Convert points to raster file matching mask_layer
geom_to_raster <- function(geom, name, mask_layer, path) {
  # convert points to raster
  call_obs <- terra::extract(mask_layer, vect(geom), cells = TRUE) %>% 
    pull(cell) %>% 
    unlist()
  obs_raster <- mask_layer
  obs_raster[call_obs] <- 1
  # write it to disk
  filename = paste0(path, taxonid, "_", name, ".asc")
  print(paste0("Writing ", filename))
  terra::writeRaster(obs_raster, filename)
}

process_obs <- function(obs, params, taxonid, mask_layer, path) {
  print(paste0("  num observations: ", nrow(obs)))
  eps <- params$epsilon[which(params$Taxon.Id == taxonids[[1]])]
  obs_euc <- add_euclidan_coords(obs)
  obs_cl <- add_clusters(obs_euc, eps)
  write_rasters(obs_cl, eps, mask_layer, path)
}

prefilter_obs <- function(obs) {
    drop_na(obs, any_of(c("decimalLatitude", "decimalLongitude")))
}

process_taxon <- function(params, taxonid, mask_layer, path) {
  print(paste0("Taxon ID: ", taxonid))
  taxon <- dplyr::filter(params, Taxon.Id == taxonid)
  obs <- get_observations(taxon$ALA.taxon) %>% 
    prefilter_obs()
  process_obs(obs, params, taxonid, mask_layer, path)
}
