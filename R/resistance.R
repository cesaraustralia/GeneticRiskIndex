
# "https://maps2.biodiversity.vic.gov.au/Models/SMP_Dromaius%20novaehollandiae_Emu_10001.zip"

taxon_path <- function(taxon, path) {
  underscored <- gsub(" ", "_", taxon$delwp_taxon)[[1]]
  path <- file.path(path, "taxa", underscored)
  dir.create(path, recursive = TRUE)
  return(path)
}

prepare_resistance_files <- function(taxa, path) {
  print("Do: prepare_resistance_files")
  for (taxon_id in taxa$taxon_concept_id) {
    print(taxon_id)
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
  dir <- taxon_path(taxon, path)
  zipname <- file.path(dir, "hdm.zip")
  download.file(url, zipname)
  unzip(zipname, exdir=dir)
  tif <- Sys.glob(file.path(dir, "*.tif"))[1]
  habitat_tif <- file.path(dir, HABITAT_RASTER)
  file.rename(tif, habitat_tif)
  habitat_tif
}

link_generic_hdm <- function(taxon, path) {
  dest <- file.path(taxon_path(taxon, path), HABITAT_RASTER)
  file.symlink(HABITAT_RASTER_PATH, dest)
}
