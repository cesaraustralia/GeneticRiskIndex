
# Main method called from scripts 
# Get observation data, cluster, and write to csv and raster
# Keeping this in the main script as it is important to verify
# the steps we are using
process_observations <- function(taxa, mask_layer, taxapath, force_download=FALSE) {
  clustered_taxa <- add_column(taxa, num_clusters = 0, error = "") 
  num_clusters <- 0
  for (i in 1:nrow(clustered_taxa)) {
    taxon <- clustered_taxa[i, ] 
    print(paste0("Taxon: ", taxon$ala_search_term))
    out <- tryCatch({
      obs <- load_or_dowload_obs(taxon, taxapath, force_download) %>%
        filter_observations(taxon) %>%
        cluster_observations(taxon)
      print(paste0("  num observations: ", nrow(obs)))
      write_cluster_rasters(obs, taxon, mask_layer, taxapath)
      c("", max(obs$clusters), "unknown")
    }, error = function(e) {
      # Record all errors with for degbugging later
      c(e, 0, "failed")
    }, finally = {
      # Classify failed taxa
    })
    clustered_taxa[i, "error"] <- out[[1]]
    clustered_taxa[i, "num_clusters"] <- out[[2]]
    clustered_taxa[i, "risk"] <- out[[3]]
  }
  return(clustered_taxa)
}

# Retrieving observation data from ALA ######################################################

# Download or load cached observation data
load_or_dowload_obs <- function(taxon, taxapath, force_download=FALSE) {
  obs_csv_path <- file.path(taxon_path(taxon, taxapath), "observations.csv")
  if (!force_download && file.exists(obs_csv_path)) {
    obs <- read_cached_observations(taxon, obs_csv_path)
    return(obs)
  } else {
    obs <- download_observations(taxon)
    print(paste0("  Writing ", obs_csv_path))
    write_csv(obs, obs_csv_path)
    return(obs)
  }
}
# Get taxon observations cached locally
read_cached_observations <- function(taxon, csv_path) {
  print(paste0("  Loading cached observations for ", taxon$ala_search_term))
  obs <- read.csv(csv_path, header = TRUE)
  return(obs)
}

# Get taxon observations from ALA using `galah`
download_observations <- function(taxon) {
  print(paste0("  Retrieving observations from ALA for ", taxon$ala_search_term))
  obs <- ala_occurrences(
    taxa = select_taxa(taxon$ala_search_term),
    filters = select_filters(
      # Limit observations by year, basis and state
      year = TIMESPAN,
      basis_of_record = BASIS,
      stateProvince = STATE
    )
  )
  return(obs)
}

# Manipulating observation data ######################################################

# Prefilter observations data #####
filter_observations <- function(obs, taxon) {
    filtered_obs <- obs %>%
      remove_bad_obs() %>%
      filter_by_fire_severity(taxon)
    print(paste0("  filtered observations: ", nrow(filtered_obs)))
    return(filtered_obs)
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

cluster_observations <- function(obs, taxon) {
    clustered_obs <- obs %>%
      add_euclidan_coords() %>%
      add_clusters(taxon$epsilon)
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
  mutate(obs, clusters = clusters$cluster)
}


# Writing observation data ######################################################

# Write the clustered and orphan observations to raster files
write_cluster_rasters <- function(obs, taxon, mask_layer, taxapath) {
  taxonpath <- taxon_path(taxon, taxapath)
  geoms <- sf::st_as_sf(obs, coords = c("x", "y"), crs = METRIC_EPSG)
  print(geoms)
  clustered <- buffer_clustered(geoms, taxon$eps)
  print(paste0("Clustered:", nrow(clustered)))
  cfn <- geom_to_raster(clustered, "clusters", taxon, mask_layer, taxonpath)
  orphans <- buffer_orphans(geoms, taxon$eps)
  print(paste0("Orphans:", nrow(orphans)))
  ofn <- geom_to_raster(orphans, "short_circuit", taxon, mask_layer, taxonpath)
  c(cfn, ofn)
}

# Add buffer around clusters
buffer_clustered <- function(geoms, eps) {
  dplyr::filter(geoms, clusters != 0) %>% 
    sf::st_buffer(dist = eps * 1000) %>% 
    dplyr::group_by(clusters) %>% 
    dplyr::summarise(clusters = unique(clusters))
}

# Add buffer around orphans
buffer_orphans <- function(geoms, eps) {
  dplyr::filter(geoms, clusters == 0) %>% 
    sf::st_buffer(dist = eps * 1000) %>% 
    dplyr::group_by(clusters) %>% 
    dplyr::summarise(clusters = unique(clusters))
}

# Convert points to raster file matching mask_layer
geom_to_raster <- function(geom, type, taxon, mask_layer, taxonpath) {
  # convert polygons to raster
  obs_raster <- terra::rasterize(terra::vect(geom), mask_layer, field = "clusters")
  # write it to disk
  filename <- file.path(taxonpath, paste0(type, ".tif"))
  print(paste0("  Writing ", filename))
  terra::writeRaster(obs_raster, filename, overwrite=TRUE)
  return(filename)
}
