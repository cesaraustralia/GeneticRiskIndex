library(sf)
library(terra)
library(dplyr)
library(tidyverse)

# obs are observations returned by galah,
# taxon is a single row of the taxa dataframe
filter_by_fire_severity <- function(obs, taxon) {
  fire_rating <- taxon$fire_rating
  # NAs go to maximum value
  fire_rating[is.na(fire_rating)] <- 6

  # read in raster layer data:
  severity_rast <- terra::rast(FIRE_SEVERITY_RASTER_PATH)

  # Make subsets of geographic points only for both lists:
  locs <- dplyr::select(obs, "decimalLongitude", "decimalLatitude")
  # Note: order of Longitude and Latitude is reversed here.

  # Create SpatialPoints objects from lists of geographic points,
  # telling R to use lat-long coordinates projection (4326):
  sf_locs <- sf::st_as_sf(locs, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326)# transform SpatialPoints objects to same projection as raster layer:
  points <- sf::st_transform(sf_locs, crs = terra::crs(severity_rast, proj4 = TRUE))

  # Extract raster layer values to new lists:
  fire_severity_points <- raster::extract(severity_rast, terra::vect(points))

  # Replace 'NA's with zeros:
  # Needed because extracted lists will have NAs for any locations
  # that fall outside of the raster layer boundaries)
  fire_severity_points[is.na(fire_severity_points)] <- 0

  # Combine extracted fire severity lists with initial data frames:
  severity_df <- add_column(obs, fire_severity = fire_severity_points$fire_severity)

  # Subset new data frames by likely survivors of a given fire intensity:
  survivors_df <- dplyr::filter(severity_df, fire_severity < fire_rating)
  return(survivors_df)
}
