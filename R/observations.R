
# Get observation data, precluster it into numbered groups, and write to both csv and raster files ##
# Main method called from scripts 
process_observations <- function(taxa, mask_layer, taxapath, force_download=FALSE, throw_errors=FALSE) {
  # Add new columns to taxa dataframe
  preclustered_taxa <- add_column(taxa, 
    num_preclusters = 0, 
    num_orphans = 0, 
    precluster_cellcount = 0, 
    orphan_cellcount = 0, 
    error = NA
  ) 
  num_preclusters <- 0

  # Loop over each taxa
  # We do some slightly complicated return value handling here to allow for error catching.
  for (i in 1:nrow(preclustered_taxa)) {
    taxon <- preclustered_taxa[i, ] 
    cat("\nTaxon: ", taxon$ala_search_term, "\n")

    # Throw errors as normal if anything goes wrong
    if (throw_errors) {
      out <- try_taxon_observations(taxon, taxapath, force_download)
    } else {
      out <- tryCatch({
        try_taxon_observations(taxon, taxapath, force_download)
      }, error = function(e) {
        error_string <- gsub("[\r\n]", " ", e)
        filter_category <- "failed" 
        # Return error for debugging later
        list(error_string, filter_category, 0, 0, 0, 0)
      })
    }

    # Add possible error messages, filter category, precluser/orphan numbers and cellcounts to dataframe
    preclustered_taxa[i, "error"] <- paste(out[1])
    preclustered_taxa[i, "filter_category"] <- out[2]
    preclustered_taxa[i, "num_preclusters"] <- out[3]
    preclustered_taxa[i, "num_orphans"] <- out[4]
    preclustered_taxa[i, "precluster_cellcount"] <- out[5]
    preclustered_taxa[i, "orphan_cellcount"] <- out[6]
  }

  return(label_by_clusters(preclustered_taxa))
}

# Block to run either with or without a try/catch block
try_taxon_observations <- function(taxon, taxapath, force_download) {
  # Download, filter and precluster observation records
  obs <- load_and_filter(taxon, taxapath, force_download)
  # Create rasters with numbered preclustered observations
  # If there are any clusters
  if (max(obs$precluster) != 0) {
    cell_counts <- write_precluster(obs, taxon, mask_layer, taxapath)
  } else {
    cell_counts <- c(0, 0)
  }
  error_string <- NA
  filter_category <- taxon$filter_category 
  num_preclusters <- max(obs$precluster)
  num_orphans <- sum(obs$precluster == 0)
  precluster_cellcount <- cell_counts[1]
  orphan_cellcount <- cell_counts[2]
  list(error_string, filter_category, num_preclusters, num_orphans, precluster_cellcount, orphan_cellcount)
}

# Load and filter observations

load_and_filter <- function(taxon, taxapath, force_download) {
  load_or_dowload_obs(taxon, taxapath, force_download) %>%
    filter_observations(taxon) %>%
    precluster_observations(taxon)
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
  cat("  Retrieving observations from ALA for ", taxon$ala_search_term, "...\n")
  obs <- ala_occurrences(
    taxa = select_taxa(taxon$ala_search_term),
    filters = ALA_FILTERS
  )
  cat("  Observations retreived successfully\n")
  return(obs)
}


# Clean observation data ######################################################

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
# TODO: Do we need this? records are filtered by location duplication anyway
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


# Cluster observation data ######################################################

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
  preclusters <- fpc::dbscan(obs[, c("x", "y")], eps = eps * 1000 * EPSILON_SENSITIVITY_SCALAR, MinPts = 3)
  mutate(obs, precluster = preclusters$cluster)
}


dispersal_distance <- function(taxon) {
  if (taxon$category == "Plants") {
    max(c(taxon$male_disp, taxon$female_disp))
  } else {
    mean(c(taxon$male_disp, taxon$female_disp))
  }
}


# Write observation data ######################################################

sf_to_df <- function(x){
  if (is(x, "sf")) {
    x %>%
      mutate(x = st_coordinates(.)[,1],
             y = st_coordinates(.)[,2]) %>%
      st_drop_geometry()
  } else {
    x
  }
}

# Write the preclustered and orphan observations to raster files
write_precluster <- function(obs, taxon, mask_layer, taxapath) {
  plotpath <- file.path(taxapath, "../plots")
  dir.create(plotpath, recursive = TRUE)
  taxonpath <- taxon_path(taxon, taxapath)
  shapes <- sf::st_as_sf(obs, coords = c("x", "y"), crs = METRIC_EPSG)
  scaled_eps <- dispersal_distance(taxon) * 1000 * EPSILON_SENSITIVITY_SCALAR

  # Create a dataframe and raster for preclusters
  preclustered <- buffer_preclustered(shapes, scaled_eps)
  cat("Preclusters:", nrow(preclustered), "\n")
  precluster_rast <- shapes_to_raster(preclustered, taxon, mask_layer, taxonpath)
  # Save a plot for fast inspection
  png(file.path(plotpath, paste0(sensitivity_name(taxon$ala_search_term, "preclusters"), ".png")))
  plot(precluster_rast, main=sensitivity_title(taxon$ala_search_term, "preclusters"))
  dev.off()
  # Write a preclusters csv, with cluster numbers attached
  pixel_freq <- freq(precluster_rast)
  left_join(shapes, pixel_freq, copy=TRUE, by=c("precluster" = "value")) %>%
    write_csv(file.path(taxonpath, paste0(sensitivity_name("preclusters"), ".csv")))
    
  # Create a dataframe and raster for orphans
  orphans <- buffer_orphans(shapes, scaled_eps)
  orphan_rast <- shapes_to_raster(orphans, taxon, mask_layer, taxonpath)
  # Save a plot for fast inspection
  png(file.path(plotpath, paste0(sensitivity_name(taxon$ala_search_term, "orphans"), ".png")))
  plot(orphan_rast, main=sensitivity_title(taxon$ala_search_term, "orphans"))
  dev.off()

  # Write an orphans csv
  write_csv(orphans, file.path(taxonpath, paste0(sensitivity_name("orphans"), ".csv")))

  # Make a crop template by trimming the empty values from a
  # combined precluster/orphan raster, with some added padding.
  crop_rast <- terra::merge(precluster_rast, orphan_rast) %>% 
    padded_trim()

  # Crop and write rasters
  precluster_filename <- file.path(taxonpath, paste0(sensitivity_name("preclusters"), ".tif"))
  orphan_filename <- file.path(taxonpath, paste0(sensitivity_name("orphans"), ".tif"))
  short_circuit_filename <- file.path(taxonpath, paste0(sensitivity_name("short_circuit"), ".tif"))
  crop(precluster_rast, crop_rast, filename=precluster_filename, overwrite=TRUE)
  crop(orphan_rast, crop_rast, filename=orphan_filename, overwrite=TRUE)
  # Make a short circuit and orphans file, as the short circuit may
  # be altered later, the orphans is only orphans.
  file.copy(orphan_filename, short_circuit_filename)

  precluster_cellcount <- sum(freq(precluster_rast))
  orphan_cellcount <- sum(freq(orphan_rast))
  return(c(precluster_cellcount, orphan_cellcount))
}

# Add the cell counts
add_cell_counts <- function() {
  taxonpath = taxon_path(taxon)
  orphans_rast <- rast(file.path(taxonpath, paste0(sensitivity_name("orphans"), ".tif")))
  preclusters_rast <- rast(file.path(taxonpath, paste0(sensitivity_name("preclusters"), ".tif")))
  orphan_cells <- count(orphans_rast)
  preclusters_cells <- count(preclusters_rast)
  mutate(taxa, prop_preclusters = prop_preclusters, prop_orphans = prop_orphans)
  npreclusters <- max(preclusters_rast)
  taxon %>% add_cell_counts(resistance_raster)
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
  obs %>% sf::st_buffer(dist = scaled_eps) %>% 
    dplyr::group_by(precluster) %>% 
    dplyr::summarise(precluster = unique(precluster))
}

# Convert points to raster file matching mask_layer
shapes_to_raster <- function(shapes, taxon, mask_layer, taxonpath) {
  print(shapes)
  shapevect <- terra::vect(shapes)
  print(shapevect)
  if (length(shapevect) > 0) {
      obs_raster <- terra::rasterize(shapevect, mask_layer, field = "precluster") 
  } else {
      mask_layer * 0
  }
}

# Calculate extension to raster and extend manually, because terra::trim 
# with padding=X has a bug if the raster does not contain the trimmed area
padded_trim <- function(rast, padding=10) {
  xresolution <- terra::xres(rast)
  yresolution <- terra::yres(rast)
  xrange <- terra::xmax(rast) - terra::xmin(rast) # number of columns
  yrange <- terra::ymax(rast) - terra::ymin(rast) # number of rows
  xPix <- ceiling(xrange / xresolution)
  yPix <- ceiling(yrange / yresolution)
  xdif <- ((padding * xresolution) - xrange) / 2 # the difference of extent divided by 2 to split on both sides
  ydif <- ((padding * yresolution) - yrange) / 2
  x <- ext(
      terra::xmin(rast) - xdif, 
      terra::xmax(rast) + xdif,
      terra::ymin(rast) - ydif,
      terra::ymax(rast) + ydif
  )

  # Trim them pad to the calculated extent
  trimmed <- terra::trim(rast)
  padded <- terra::extend(trimmed, x)
  return(padded)
}

# Label taxa that we don't need to process due to cluster numbers ######################################

label_by_clusters <- function(taxa) {
  taxa %>%
    label_high_orphan_area() %>%
    label_many_clusters() %>%
    label_few_clusters() %>%
    label_no_clusters()
}

# - That have too many orphan cells compared to precluster cells
label_high_orphan_area <- function(taxa) {
  id <- taxa$orphan_cellcount / taxa$precluster_cellcount > MAX_ORPHAN_PRECLUSTER_RATIO
  taxa$filter_category[id] <- "high_ratio_orphan_cells"  
  return(taxa)
}

# - That have too many preclusters
label_many_clusters <- function(taxa) {
  id <- taxa$num_preclusters > MAX_CLUSTERS
  taxa$risk[id] <- "abundant"
  taxa$filter_category[id] <- "many_clusters"  
  return(taxa)
}

# - That have too few preclusters
label_few_clusters <- function(taxa) {
  id <- taxa$num_preclusters < MIN_CLUSTERS & taxa$num_preclusters > 0
  taxa$risk[id] <- "rare"
  taxa$filter_category[id] <- "few_clusters"  
  return(taxa)
}

# - That have no preclusters
label_no_clusters <- function(taxa) {
  id <- taxa$num_preclusters == 0
  taxa$risk[id] <- "rare"
  taxa$filter_category[id] <- "no_clusters"  
  return(taxa)
}
