
# Main method to call from scripts
# Set up files for use by Circuitscape.jl later on
# taxa is a dataframe, taxonpath is the directory
# where taxon directries are created
prepare_resistance_files <- function(taxa, taxapath) {
  for (i in 1:nrow(taxa)) {
    taxon <- taxa[i, ] 
    tryCatch({
      crop_filename <- file.path(taxon_path(taxon, taxapath), "preclusters.tif")
      if (file.exists(crop_filename)) {
        if (taxon$resist_model_type[[1]] == "Species") {
          download_hdm(taxon, taxapath, crop_filename)
        } else {
          use_generic_hdm(taxon, taxapath, crop_filename)
        }
      }
    }, error = function(e) {
      warning("Failed to download resistance file for ", taxon$ala_search_term, " ", e)
    })
  }
}

# Download the HDM layer for this taxon
# Formatted as:
# "https://maps2.biodiversity.vic.gov.au/Models/SMP_Dromaius%20novaehollandiae_Emu_10001.zip"
download_hdm <- function(taxon, taxapath, crop_filename) {
  cat("Downloading specific habitat layer for", taxon$ala_search_term, "\n")
  taxon_id <- taxon$vic_taxon_id[[1]]
  taxon_escaped <- gsub(" ", "%20", taxon$delwp_taxon)[[1]]
  common_name <- gsub(" ", "%20", taxon$delwp_common_name)[[1]]
  url <- paste0("https://maps2.biodiversity.vic.gov.au/Models/SMP_", taxon_escaped, "_", common_name, "_", taxon_id, ".zip")
  taxon_dir <- taxon_path(taxon, taxapath)
  download_dir <- file.path(taxon_dir, "download")
  dir.create(download_dir, recursive = TRUE)
  zippath <- file.path(download_dir, "hdm.zip")
  # If the download doesn't exist, download it
  if (!dir.exists(download_dir) || is.na(Sys.glob(file.path(download_dir, "*.tif"))[1])) { 
    download.file(url, zippath)
    unzip(zippath, exdir=download_dir)
    file.remove(zippath)
  }
  habitat_filename <- Sys.glob(file.path(download_dir, "*.tif"))[1]
  resistance_filename <- file.path(taxon_path(taxon, taxapath), RESISTANCE_RASTER)
  resistance_raster <- terra::rast(habitat_filename) %>%
    habitat_to_resistance() %>% 
    crop_resistance(taxon, crop_filename)
  terra::writeRaster(resistance_raster, filename=resistance_filename, overwrite=TRUE)
}

# Invert percentage from % habitat quality to % movement resistance
habitat_to_resistance <- function(habitat_raster) {
  101 - habitat_raster
}

# Crop a section of the generic HDM resistance file as the resisance file for this taxon
use_generic_hdm <- function(taxon, taxapath, crop_filename) {
  cat("Using generic resistance HDM for", taxon$ala_search_term, "\n")
  resistance_filename <- file.path(taxon_path(taxon, taxapath), RESISTANCE_RASTER)
  terra::rast(HABITAT_RASTER_PATH) %>%
    habitat_to_resistance() %>%
    crop_resistance(taxon, taxapath) %>%
    terra::writeRaster(filename=resistance_filename, overwrite=TRUE)
}

crop_resistance <- function(resistance_raster, crop_filename) {
  crop_template <- terra::rast(crop_filename)
  # Crop the resistance_raster to match "preclusters.tif"
  terra::crop(resistance_raster, crop_template)
}


