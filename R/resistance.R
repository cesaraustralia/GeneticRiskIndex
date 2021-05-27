
# "https://maps2.biodiversity.vic.gov.au/Models/SMP_Dromaius%20novaehollandiae_Emu_10001.zip"

taxon_path <- function(taxon, path) {
  underscored <- gsub(" ", "_", taxon$DELWP.taxon)[[1]]
  path <- file.path(path, "taxa", underscored)
  dir.create(path, recursive = TRUE)
  return(path)
}

prepare_resistance_files <- function(taxa, path) {
  for (taxonid in taxa$Taxon.Id) {
    taxon <- filter(taxa, Taxon.Id == taxonid)
    if (taxon$Resist.model.type[[1]] == "Species") {
      download_hdm(taxon, path)
    } else {
      link_generic_hdm(taxon, path)
    }
  }
}

download_hdm <- function(taxon, path) {
  taxonid <- taxon$Taxon.Id[[1]]
  taxon_escaped <- gsub(" ", "%20", taxon$DELWP.taxon)[[1]]
  common_name <- gsub(" ", "%20", taxon$DELWP.common.name)[[1]]
  url <- paste0("https://maps2.biodiversity.vic.gov.au/Models/SMP_", taxon_escaped, "_", common_name, "_", taxonid, ".zip")
  dir <- taxon_path(taxon, path)
  zipname <- paste0(dir, "/hdm.zip")
  download.file(url, zipname)
  unzip(zipname, exdir=dir)
  tif <- Sys.glob(file.path(dir, "*", "*.tif"))[1]
  habitat_tif <- file.path(dir, "habitat.tif")
  file.rename(tif, habitat_tif)
  habitat_tif
}

link_generic_hdm <- function(taxon, path) {
  generic <- file.path(path, "sbv.tif")
  dest <- file.path(taxon_path(taxon, path), "habitat.tif")
  file.symlink(generic, dest)
}
