# Retrieving observation data from ALA ######################################################

# Get taxon observations from ALA using `galah`
get_observations <- function(taxon_name) {
  print(paste0("  Retrieving observations from ALA for ", taxon_name))
  obs <- ala_occurrences(
    taxa = select_taxa(taxon_name),
    filters = select_filters(
      year = TIMESPAN,
      basis_of_record = BASIS,
      stateProvince = STATE
    ),
  )
  return(obs)
}


# Manipulating observation data ######################################################

cluster_observations <- function(taxa, mask_layer, path) {
  for (taxon_id in taxa$vic_taxon_id) {
    print(paste0("Taxon ID: ", taxon_id))
    taxon <- filter(taxa, vic_taxon_id == taxon_id)
    obs <- cluster_taxon_obs(taxon, mask_layer, path)
    taxonpath <- taxon_path(taxon, path)
    obs_csv_path <- file.path(taxonpath, "observations.csv")
    print(paste0("  Writing ", obs_csv_path))
    write_csv(obs, obs_csv_path)
    write_rasters(obs, taxon, mask_layer, taxonpath)
  }
}

# Retrieve observations, filter and process for a single taxon
cluster_taxon_obs <- function(taxon, mask_layer, path) {
  obs <- get_observations(taxon$ala_search_term) %>% 
    prefilter_obs() %>%
    add_euclidan_coords() %>%
    add_clusters(taxon$epsilon)
  print(paste0("  num observations: ", nrow(obs)))
  return(obs)
}

# Prefilter observations data #####

prefilter_obs <- function(obs) {
  obs %>% remove_missing_coords() %>%
    remove_location_duplicates()
}

remove_missing_coords <- function(obs) {
  drop_na(obs, any_of(c("decimalLatitude", "decimalLongitude")))
}

remove_location_duplicates <- function(obs) {
  # Sort by date first so we take the newest record
  obs %>% arrange(desc(eventDate)) %>%
    distinct(decimalLatitude, decimalLongitude, .keep_all = TRUE)
}

# Add transformed coordinates "x" an "y" for accurate distance calculations
add_euclidan_coords <- function(obs) {
    sf::st_as_sf(obs, coords = c("decimalLongitude", "decimalLatitude"), crs = LATLON_EPSG) %>% sf::st_transform(crs = METRIC_EPSG) %>% mutate(x = sf::st_coordinates(.)[,1], y = sf::st_coordinates(.)[,2]) %>% 
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
write_rasters <- function(obs, taxon, mask_layer, path) {
  geoms <- sf::st_as_sf(obs, coords = c("x", "y"), crs = METRIC_EPSG)
  clustered <- buffer_clustered(geoms, taxon$eps)
  orphans <- buffer_orphans(geoms, taxon$eps)
  geom_to_raster(orphans, "orphans", taxon, mask_layer, path)
  geom_to_raster(clustered, "clusters", taxon, mask_layer, path)
}

# Convert points to raster file matching mask_layer
geom_to_raster <- function(geom, type, taxon, mask_layer, path) {
  # convert points to raster
  cell_obs <- terra::extract(mask_layer, vect(geom), cells = TRUE) %>% 
    pull(cell) %>% 
    unlist()
  obs_raster <- mask_layer
  obs_raster[cell_obs] <- 1
  # write it to disk
  filename = file.path(path, paste0(type, ".tif"))
  print(paste0("  Writing ", filename))
  terra::writeRaster(obs_raster, filename, overwrite=TRUE)
  return(filename)
}
