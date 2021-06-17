
# Main method called from scripts 

# Get observation data, cluster it into numbered groups, and write to 
# both csv and raster files.
process_observations <- function(taxa, mask_layer, taxapath, force_download=FALSE) {
  clustered_taxa <- add_column(taxa, num_clusters = 0, error = "") 
  num_clusters <- 0
  for (i in 1:nrow(clustered_taxa)) {
    taxon <- clustered_taxa[i, ] 
    cat("\nTaxon: ", taxon$ala_search_term, "\n")
    # Try-catch-finally block to catch any errors that 
    # happen for Individual taxa
    out <- tryCatch({
      # Download, filter and cluster observation records
      obs <- load_or_dowload_obs(taxon, taxapath, force_download) %>%
        filter_observations(taxon) %>%
        cluster_observations(taxon) 
      # Create rasters with numbered clustered observations
      write_cluster_rasters(obs, taxon, mask_layer, taxapath)

      list("", max(obs$cluster), "unknown")
    }, error = function(e) {
      error_without_linebreaks <- gsub("[\r\n]", "", e)
      # Return error for debugging later
      list(error_without_linebreaks, 0, "failed")
    })

    # Add portential error messages, cluser number, and risk category to data.
    clustered_taxa[i, "error"] <- paste(out[1])
    clustered_taxa[i, "num_clusters"] <- out[2]
    clustered_taxa[i, "risk"] <- out[3]
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
    cat("  Writing ", obs_csv_path, "\n")
    write_csv(obs, obs_csv_path)
    return(obs)
  }
}

# Get taxon observations that are saved locally
read_cached_observations <- function(taxon, csv_path) {
  cat("  Loading cached observations for ", taxon$ala_search_term, "\n")
  obs <- read.csv(csv_path, header = TRUE)
  return(obs)
}

# Get taxon observations from ALA using `galah`
download_observations <- function(taxon) {
  cat("  Retrieving observations from ALA for ", taxon$ala_search_term, "\n")
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
    obs %>%
      maybe_remove_subspecies(taxon) %>%
      remove_bad_obs() %>%
      filter_by_fire_severity(taxon)
}

# Remove subspecies observations when we are working with the
# whole species, as subspecies will be duplicates ??
maybe_remove_subspecies <- function(obs, taxon) {
  if (taxon$taxon_level == "Base") {
    return(dplyr::filter(obs, scientificName == taxon$ala_search_term))
  } else {
    return(obs)
  }
}

# Remove observation records with obvious flaws
remove_bad_obs <- function(obs) {
  obs %>% remove_missing_coords() %>%
    remove_location_duplicates()
}

# Remove coordinates with NA values
remove_missing_coords <- function(obs) {
  drop_na(obs, any_of(c("decimalLatitude", "decimalLongitude")))
}

# Remove duplicate locations
remove_location_duplicates <- function(obs) {
  # Sort by date first so we take the newest record
  obs %>% arrange(desc(eventDate)) %>%
    distinct(decimalLatitude, decimalLongitude, .keep_all = TRUE)
}


# Clustering observation data ######################################################

# Categorise clusters and add clusters column to dataframe
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
  mutate(obs, cluster = clusters$cluster)
}


# Writing observation data ######################################################

# Write the clustered and orphan observations to raster files
write_cluster_rasters <- function(obs, taxon, mask_layer, taxapath) {
  taxonpath <- taxon_path(taxon, taxapath)
  geoms <- sf::st_as_sf(obs, coords = c("x", "y"), crs = METRIC_EPSG)
  clustered <- buffer_clustered(geoms, taxon$eps)
  cat("Clusters:", nrow(clustered), "\n")
  cfn <- geom_to_raster(clustered, "clusters", taxon, mask_layer, taxonpath)
  orphans <- buffer_orphans(geoms, taxon$eps)
  cat("Orphans:", nrow(orphans), "\n")
  ofn <- geom_to_raster(orphans, "short_circuit", taxon, mask_layer, taxonpath)
  c(cfn, ofn)
}

# Add buffer around clusters
buffer_clustered <- function(geoms, eps) {
  dplyr::filter(geoms, cluster != 0) %>% 
    sf::st_buffer(dist = eps * 1000) %>% 
    dplyr::group_by(cluster) %>% 
    dplyr::summarise(cluster = unique(cluster))
}

# Add buffer around orphans
buffer_orphans <- function(geoms, eps) {
  dplyr::filter(geoms, cluster == 0) %>% 
    # TODO: remove 1.9 multiplier and use new data columns
    sf::st_buffer(dist = eps * 1000 / 1.9) %>%
    dplyr::group_by(cluster) %>% 
    dplyr::summarise(cluster = unique(cluster))
}

# Convert points to raster file matching mask_layer
geom_to_raster <- function(geom, type, taxon, mask_layer, taxonpath) {
  # convert polygons to raster
  obs_raster <- terra::rasterize(terra::vect(geom), mask_layer, field = "cluster")
  # write it to disk
  filename <- file.path(taxonpath, paste0(type, ".tif"))
  cat("  Writing ", filename, "\n")
  terra::writeRaster(obs_raster, filename, overwrite=TRUE)
  return(filename)
}
