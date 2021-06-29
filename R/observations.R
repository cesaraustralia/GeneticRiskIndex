
# Main method called from scripts 

# Get observation data, precluster it into numbered groups, and write to 
# both csv and raster files.
process_observations <- function(taxa, mask_layer, taxapath, force_download=FALSE, error=FALSE) {
  preclustered_taxa <- add_column(taxa, num_preclusters = 0, error = NA) 
  num_preclusters <- 0
  for (i in 1:nrow(preclustered_taxa)) {
    taxon <- preclustered_taxa[i, ] 
    cat("\nTaxon: ", taxon$ala_search_term, "\n")
    # Try-catch-finally block to catch any errors that 
    # happen for individual taxa
    if (error) {
      obs <- load_filter_write(taxon, taxapath, force_download)
      # Add precluser number to data.
      preclustered_taxa[i, "num_preclusters"] <- max(obs$precluster)
    } else {
      out <- tryCatch({
        # Download, filter and precluster observation records
        obs <- load_filter_write(taxon, taxapath, force_download)
        list(NA, max(obs$precluster), obs$filter_category)
      }, error = function(e) {
        error_without_linebreaks <- gsub("[\r\n]", " ", e)
        # Return error for debugging later
        list(error_without_linebreaks, 0, "failed")
      })
      # Add possible error messages, precluser number and risk category to data.
      preclustered_taxa[i, "error"] <- paste(out[1])
      preclustered_taxa[i, "num_preclusters"] <- out[2]
      preclustered_taxa[i, "filter_category"] <- out[3]
    }
  }
  preclustered_taxa %>%
    label_many_clusters() %>%
    label_few_clusters() %>%
    label_no_clusters()
}

load_filter_write <- function(taxon, taxapath, force_download) {
  obs <- load_or_dowload_obs(taxon, taxapath, force_download) %>%
    filter_observations(taxon) %>%
    precluster_observations(taxon)
  # Create rasters with numbered preclustered observations
  # If there are any clusters
  if (max(obs$precluster) != 0) {
    write_precluster_rasters(obs, taxon, mask_layer, taxapath)
  }
  return(obs)
}

label_many_clusters <- function(taxa) {
  # Taxa that we don't need to process - these have a lot of preclusters
  id <- taxa$num_preclusters > MAX_CLUSTERS
  taxa$risk[id] <- "abundant"
  taxa$filter_category[id] <- "many_clusters"  
  return(taxa)
}

label_few_clusters <- function(taxa) {
  id <- taxa$num_preclusters < MIN_CLUSTERS & taxa$num_preclusters > 0
  taxa$risk[id] <- "rare"
  taxa$filter_category[id] <- "few_clusters"  
  return(taxa)
}

label_no_clusters <- function(taxa) {
  id <- taxa$num_preclusters == 0
  taxa$risk[id] <- "rare"
  taxa$filter_category[id] <- "no_clusters"  
  return(taxa)
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

# Filter observations data #####
filter_observations <- function(obs, taxon) {
    obs %>%
      # maybe_remove_subspecies(taxon) %>%
      remove_missing_coords() %>%
      remove_location_duplicates() %>%
      filter_by_fire_severity(taxon)
}

# Remove subspecies observations when we are working with the
# whole species, as subspecies will be duplicates ??
# TODO: Do we need this? records are filtered by location
# duplication anyway
maybe_remove_subspecies <- function(obs, taxon) {
  if (taxon$taxon_level == "Base") {
    return(dplyr::filter(obs, scientificName == taxon$ala_search_term))
  } else {
    return(obs)
  }
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

# Categorise preclusters and add preclusters column to dataframe
precluster_observations <- function(obs, taxon) {
  obs %>%
    add_euclidan_coords() %>%
    scan_clusters(taxon$epsilon)
}

# Add transformed coordinates "x" an "y" for accurate distance calculations
add_euclidan_coords <- function(obs) {
  sf::st_as_sf(obs, coords = c("decimalLongitude", "decimalLatitude"), crs = LATLON_EPSG) %>% 
    sf::st_transform(crs = METRIC_EPSG) %>% 
    mutate(x = sf::st_coordinates(.)[,1], y = sf::st_coordinates(.)[,2]) %>% 
    sf::st_drop_geometry()
}

# Scan preclusters and add precluster index to observations
scan_clusters <- function(obs, eps) {
  preclusters <- fpc::dbscan(obs[, c("x", "y")], eps = eps * 1000, MinPts = 3)
  mutate(obs, precluster = preclusters$cluster)
}


# Writing observation data ######################################################

# Write the preclustered and orphan observations to raster files
write_precluster_rasters <- function(obs, taxon, mask_layer, taxapath) {
  taxonpath <- taxon_path(taxon, taxapath)
  shapes <- sf::st_as_sf(obs, coords = c("x", "y"), crs = METRIC_EPSG)
  scaled_eps <- taxon$eps * 1000 / 1.9

  # Create a full-sized raster for preclusters
  preclustered <- buffer_preclustered(shapes, scaled_eps)
  cat("Preclusters:", nrow(preclustered), "\n")
  precluster_rast <- shape_to_raster(preclustered, taxon, mask_layer, taxonpath)
    
  # Create a full-sized raster for orphans
  orphans <- buffer_orphans(shapes, scaled_eps)
  cat("Orphans:", nrow(orphans), "\n")
  orphan_rast <- shape_to_raster(orphans, taxon, mask_layer, taxonpath)


  # Make a crop template by trimming the empty values from a
  # combined precluster/orphan raster, with some added padding.
  crop_rast = terra::merge(precluster_rast, orphan_rast) %>% 
      trim(padding=0)

  # Crop and write rasters
  precluster_filename <- file.path(taxonpath, "preclusters.tif")
  orphan_filename <- file.path(taxonpath, "orpans.tif")
  short_circuit_filename <- file.path(taxonpath, "short_circuit.tif")
  crop(precluster_rast, crop_rast, filename=precluster_filename, overwrite=TRUE)
  crop(orphan_rast, crop_rast, filename=orphan_filename, overwrite=TRUE)
  # Make a short circuit and orphans file, as the short circuit may
  # be altered later, the orphans is only orphans.
  file.copy("orpans.tif", "short_circuit.tif")

  return(c(precluster_filename, orphan_filename))
}

# Add buffer around preclusters
buffer_preclustered <- function(obs, scaled_eps) {
  dplyr::filter(obs, precluster != 0) %>% 
    buffer_obs(scaled_eps)
}

# Add buffer around orphans
buffer_orphans <- function(shapes, scaled_eps) {
  dplyr::filter(shapes, precluster == 0) %>% 
    buffer_obs(scaled_eps)
}

buffer_obs <- function(obs, scaled_eps) {
  obs %>%
    sf::st_buffer(dist = scaled_eps) %>% 
    dplyr::group_by(precluster) %>% 
    dplyr::summarise(precluster = unique(precluster))
}

# Convert points to raster file matching mask_layer
shape_to_raster <- function(shape, taxon, mask_layer, taxonpath) {
  if (length(vect(shape)) > 0) {
      obs_raster <- terra::rasterize(terra::vect(shape), mask_layer, field = "precluster") 
  } else {
      mask_layer * 0
  }
}
