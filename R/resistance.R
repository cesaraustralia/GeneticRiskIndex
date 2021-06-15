

# Main method to call from scripts
# Set up files for use by Circuitscape.jl later on
# taxa is a dataframe, taxonpath is the directory
# where taxon directries are created
prepare_resistance_files <- function(taxa, taxonpath) {
  for (i in 1:nrow(taxa)) {
    taxon <- taxa[i, ] 
    if (taxon$resist_model_type[[1]] == "Species") {
      download_hdm(taxon, taxonpath)
    } else {
      link_generic_hdm(taxon, taxonpath)
    }
  }
}

# Download the HDM layer for this taxon
# Formatted as:
# "https://maps2.biodiversity.vic.gov.au/Models/SMP_Dromaius%20novaehollandiae_Emu_10001.zip"
download_hdm <- function(taxon, path) {
  taxon_id <- taxon$vic_taxon_id[[1]]
  taxon_escaped <- gsub(" ", "%20", taxon$delwp_taxon)[[1]]
  common_name <- gsub(" ", "%20", taxon$delwp_common_name)[[1]]
  url <- paste0("https://maps2.biodiversity.vic.gov.au/Models/SMP_", taxon_escaped, "_", common_name, "_", taxon_id, ".zip")
  taxon_dir <- taxon_path(taxon, path)
  download_dir <- file.path(taxon_dir, "download")
  dir.create(download_dir, recursive = TRUE)
  zippath <- file.path(download_dir, "hdm.zip")
  # If the download doesn't exist, download it
  if (!dir.exists(download_dir) || is.na(Sys.glob(file.path(download_dir, "*.tif"))[1])) { 
    download.file(url, zippath)
    unzip(zippath, exdir=download_dir)
    file.remove(zippath)
  }
  habitat_tif <- Sys.glob(file.path(download_dir, "*.tif"))[1]
  resistance_tif <- file.path(taxon_dir, RESISTANCE_RASTER)
  habitat_to_resistance(habitat_tif, resistance_tif)
}

# Invert percentage from % habitat quality to % movement resistance
habitat_to_resistance <- function(habitat_path, resistance_path) {
  cat("Create resistance tif:\n", resistance_path, "\nfrom habitat tif:\n", habitat_path, "\n\n")
  terra::writeRaster(101 - terra::rast(habitat_path), resistance_path, overwrite=TRUE)
}

# Make a symlink to the generic HDM file instead of
# Downloading a specific file
link_generic_hdm <- function(taxon, path) {
  dest <- file.path(taxon_path(taxon, path), RESISTANCE_RASTER)
  cat("Linking generic resistance HDM for", taxon$ala_search_term, "to:\n", dest, "\n\n")
  file.symlink(RESISTANCE_RASTER_PATH, dest)
}
