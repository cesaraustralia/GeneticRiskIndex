
# "https://maps2.biodiversity.vic.gov.au/Models/SMP_Dromaius%20novaehollandiae_Emu_10001.zip"

taxon_path <- function(taxon, path) {
  underscored <- gsub(" ", "_", taxon$delwp_taxon)[[1]]
  path <- file.path(path, underscored)
  dir.create(path, recursive = TRUE)
  return(path)
}

prepare_resistance_files <- function(taxa, path) {
  for (taxon_id in taxa$taxon_concept_id) {
    taxon <- filter(taxa, taxon_concept_id == taxon_id)
    if (taxon$resist_model_type[[1]] == "Species") {
      download_hdm(taxon, path)
    } else {
      link_generic_hdm(taxon, path)
    }
  }
}

download_hdm <- function(taxon, path) {
  taxon_id <- taxon$vic_taxon_id[[1]]
  taxon_escaped <- gsub(" ", "%20", taxon$delwp_taxon)[[1]]
  common_name <- gsub(" ", "%20", taxon$delwp_common_name)[[1]]
  url <- paste0("https://maps2.biodiversity.vic.gov.au/Models/SMP_", taxon_escaped, "_", common_name, "_", taxon_id, ".zip")
  taxon_dir <- taxon_path(taxon, path)
  download_dir <- file.path(taxon_dir, "download")
  dir.create(download_dir, recursive = TRUE)
  zippath <- file.path(download_dir, "hdm.zip")
  download.file(url, zippath)
  unzip(zippath, exdir=download_dir)
  file.remove(zippath)
  habitat_tif <- Sys.glob(file.path(download_dir, "*.tif"))[1]
  resistance_tif <- file.path(taxon_dir, RESISTANCE_RASTER)
  habitat_to_resistance(habitat_tif, resistance_tif)
}

habitat_to_resistance <- function(habitat_path, resistance_path) {
  terra::writeRaster(100 - terra::rast(habitat_path), resistance_path)
}

link_generic_hdm <- function(taxon, path) {
  dest <- file.path(taxon_path(taxon, path), RESISTANCE_RASTER)
  file.symlink(RESISTANCE_RASTER_PATH, dest)
}
