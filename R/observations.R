# Retrieving observation data from ALA ######################################################

# Get taxon observations from ALA using `galah`
get_observations <- function(taxon) {
  ala_search_term <- taxon$ala_search_term
  print(paste0("  Retrieving observations from ALA for ", ala_search_term))
  obs <- ala_occurrences(
    taxa = select_taxa(ala_search_term),
    filters = select_filters(
      # Limit observations by year, basis and state
      year = TIMESPAN,
      basis_of_record = BASIS,
      stateProvince = STATE
    )
  )
  return(obs)
}

# Download or load cached observation data
load_or_dowload_obs <- function(taxon, path, force_download=FALSE) {
  obs_csv_path <- file.path(taxon_path(taxon, path), "observations.csv")
  if (!force_download && file.exists(obs_csv_path)) {
    obs <- read.csv(obs_csv_path, header = TRUE)
    return(obs)
  } else {
    obs <- get_observations(taxon)
    print(paste0("  Writing ", obs_csv_path))
    write_csv(obs, obs_csv_path)
    return(obs)
  }
}

# Get observation data, cluster, and write to csv and raster
# Keeping this in the main script as it is important to verify
# the steps we are using
process_observations <- function(taxa, mask_layer, path, force_download=FALSE) {
  for (ala_search_term in taxa$ala_search_term) {
    taxon <- filter(taxa, ala_search_term == ala_search_term)
    print(paste0("Taxon: ", taxon$ala_search_term))
    obs <- load_or_dowload_obs(taxon, taxapath, force_download) %>%
      filter_observations(taxon)
    print(paste0("  num observations: ", nrow(obs)))
    write_clustered_obs(obs, taxon, path)
  }
}

# Manipulating observation data ######################################################

# Prefilter observations data #####
filter_observations <- function(obs, taxon) {
    filtered_obs <- obs %>%
      remove_bad_obs() %>%
      filter_by_fire_severity(taxon)
    print(paste0("  filtered observations: ", nrow(filtered_obs)))
    clustered_obs <- filtered_obs %>%
      add_euclidan_coords() %>%
      add_clusters(taxon$epsilon)
    return(clustered_obs)
}

remove_bad_obs <- function(obs) {
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
    sf::st_as_sf(obs, coords = c("decimalLongitude", "decimalLatitude"), crs = LATLON_EPSG) %>% 
        sf::st_transform(crs = METRIC_EPSG) %>% 
        mutate(x = sf::st_coordinates(.)[,1], y = sf::st_coordinates(.)[,2]) %>% 
        sf::st_drop_geometry()
}

# Scan clusters and add cluster index to observations
add_clusters <- function(obs, eps) {
  clusters <- fpc::dbscan(obs[, c("x", "y")], eps = eps * 1000, MinPts = 3)
  print(paste0("Clusters: ", nrow(clusters)))
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


# Writing observation data ######################################################

# Write clustered data
write_clustered_obs <- function(obs, taxon, path) {
    # Write csv and raster files for observations and clusters
    taxonpath <- taxon_path(taxon, path)
    write_rasters(obs, taxon, mask_layer, taxonpath)
}

# Write the clustered and orphan observations to raster files
write_rasters <- function(obs, taxon, mask_layer, path) {
  geoms <- sf::st_as_sf(obs, coords = c("x", "y"), crs = METRIC_EPSG)
  clustered <- buffer_clustered(geoms, taxon$eps)
  orphans <- buffer_orphans(geoms, taxon$eps)
  geom_to_raster(orphans, "short_circuit", taxon, mask_layer, path)
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
