# Roozbeh's script for DBSCAN clustering...
# required libraries
library(dplyr)
library(fpc)
library(sf)

# read data
# DELWP records file needs
# headers = "latin_name", "Latitude", "Longitude"
# currently has "Species" instead of "latin_name"

spdata <- read.csv("C:/Users/peter/Documents/R/ALA2/koala2.csv")
# epsilon file needs headers = "species", "epsilon1", "epsilon2"
## DELWP list has 'epsilon.value' instead of 'epsilon2'
# DELWP list needs 7 species added for epsilon file
epsilon <- read.csv("C:/Users/peter/Documents/R/ALA2/epsilon2.csv")

head(spdata)
head(epsilon)

# metric reference system; epsg code
metric_ref <- 3111

# do all species name match?
epsilon$species %in% spdata$latin_name

# change the coordinate system to euclidean space
# WGS84 (EPSG: 4326)
# alternative coordinate systems: GDA94 / Geoscience Australia Lambert (EPSG: 3112)
# GDA94 Vicgrid (EPSG: 3111), GDA94 (EPSG: 4283)
# reference: https://spatialreference.org/ref/?&search=australia
# GDA2020 pending?
sp_euclid <- sf::st_as_sf(spdata, coords = c("Longitude", "Latitude"), crs = 4326) %>% 
  sf::st_transform(crs = metric_ref) %>% 
  mutate(x = sf::st_coordinates(.)[,1],
         y = sf::st_coordinates(.)[,2]) %>% 
  sf::st_drop_geometry()

sp_names <- unique(sp_euclid$latin_name)
sp_names

# create empty data.frame
final_df <- data.frame()

# set a seed for a consistent result? e.g. set.seed(665544)

for(i in sp_names){
  eps <- epsilon$epsilon[which(epsilon$species == i)]
  
  sp <- filter(sp_euclid, latin_name == i)
  clusters <-  fpc::dbscan(sp[, c("x", "y")], eps = eps * 1000, MinPts = 3)
  sp <- mutate(sp, clusters = clusters$cluster) %>% 
    sf::st_as_sf(coords = c("x", "y"), crs = metric_ref) %>% 
    sf::st_transform(crs = 4326) %>% 
    mutate(Longitude = sf::st_coordinates(.)[,1],
           Latitude = sf::st_coordinates(.)[,2]) %>% 
    sf::st_drop_geometry()
  # compute DBSCAN using fpc package
  final_df <- bind_rows(final_df, sp)
  print(i)
}

head(final_df)

# write to csv
write.csv(final_df, "C:/Users/peter/Documents/R/ALA2/Koala3.csv")

