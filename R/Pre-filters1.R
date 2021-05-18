## FILTERING OF RAW DATA DOWNLOADED FROM ALA website:
library(tidyverse) # includes dplyr & readr
library(lubridate)

# read in individual parts...
### better to read in multiple files for all parts?... ###
## work around: run separately for each part ##
## amend names for variables and input file each time as required ##
ALA_10a <- read.csv("records-2021-02-15_part10.csv", header = TRUE)
# raw ALA data in this format has 58 fields - see 'headers' file
# that was part of zip file for explanation and database origin
# retain classification fields ('Vernacular.name', 'Phylum', 'Class',
#   'Order', 'Family', 'Genus', 'Species', 'Subspecies'),
#   'Latitude', 'Longitude', Coordinate.Uncertainty.in.Metres',
#   'State...parsed', 'IBRA.7.Regions', 'Year,
#   'Event.Date...parsed', 'Basis.Of.Record'
ALA_10b <- ALA_10a %>% select(8,10:16,30,31,33,35,38,45,48,51)
# better to use column names in place of column numbers in code
# in case format of data retrieved from ALA changes

# rename some columns for convenience
#  (needs new name to be first in code)
ALA_10c <- ALA_10b %>% rename(Vernacular = Vernacular.name,
      Uncertainty = Coordinate.Uncertainty.in.Metres,
      State = State...parsed,
      IBRA7 = IBRA.7.Regions,
      Date = Event.Date...parsed,
      Basis = Basis.Of.Record)

# extract year from Date column & convert to numeric:
ALA_10c$Date <- as.POSIXct(ALA_10c$Date, format="%Y-%m-%d")
# convert extracted value to numeric
ALA_10c$Date <- as.numeric(format(ALA_10c$Date, format="%Y"))
# alternative: convert to integer instead? 
# ALA_10c$Date <- as.integer(format(ALA_10c$Date, format="%Y"))

# filter out records where either Year or Date missing:
ALA_10d <- subset(ALA_10c, !is.na(Date) | !is.na(Year))
# should be no records where Year and Date are present but different:
# dtest <- subset(ALA_10c, Year != Date)
# resulting dtest object should be empty

# filter out old records where Year or Date is < 1960:
ALA_10e <- subset(ALA_10c, Year >= 1960 | Date >= 1960)

# keep only records where the basis is HumanObservation
ALA_10f <- subset(ALA_10e, Basis == "HumanObservation")
## can now remove this last column (column 16)
ALA_10f <- ALA_10f %>% select(1:15)

# filter out records where Species is missing:
ALA_10g <- subset(ALA_10f, Species != "")


# combine all parts (took about 9 minutes)
### amend so script picks up all parts ###
koala <- rbind(ALA_1a,ALA_2a,ALA_3a,ALA_4a,ALA_5a,ALA_6a,ALA_7a,
               ALA_8a,ALA_9a,ALA_10g)
# 33,978,480 records in total

# sort on Species (ascending), Year and Date (descending order):
# this is required so that when filtering out duplicate records
# for a given species that are at the exact same location, the most
# recent records will be the one retained
koala <- koala[order(koala$Species, -koala$Year, koala$Date),]

# somehow ended up with 949 records with Species == "",
# remove these:
koala <- subset(koala, Species != "")

### data downloaded from ALA may also include records for some
###  species that are not in our DELWP list
### Better to also filter these out at this step ###
## work around: identify extraneous records by
##  comparing lists in Excel with vlookup
##  then remove ('junk1)

# list of junk taxa to remove from initial ALA data download
junk1 <- c("Anthochaera lunulata","Bartramia longicauda",
           "Calidris alpina","Calidris fusicollis","Calidris mauri",
           "Gallinago megala","Gallinago stenura",
           "Malurus pulcherrimus","Ninox novaeseelandiae",
           "Phalaropus fulicarius",
           "Pittosporum bicolor x Pittosporum undulatum",
           "Platycercus adscitus","Ptilonorhynchus maculatus",
           "Rhipidura dryas","Steganopus tricolor",
           "Threskiornis moluccus","Tringa cinerea",
           "Tringa flavipes","Tringa incana","Tringa totanus")

# save as combined .csv file:
write_csv(koala,"Koala1.csv")

# count number of filtered records for each Species:
# uses count function from plyr package
koala1.recs <- plyr::count(koala$Species)

# filter out records where location is duplicated for a given Species:
koala2 <- koala %>% distinct(Species, Latitude,
      Longitude, .keep_all = TRUE)
# 13,208,745 unique records in total

# save as combined .csv file:
write_csv(koala2,"Koala2.csv")

# count number of unique records for each Species:
# uses count function from plyr package
koala2.sp <- plyr::count(koala2$Species)

# summarize records per Species for Victoria only:
# create new column
Koala2$Vic <- Koala2$State
# change new column to conditional 1s or 0s:
Koala2$Vic[Koala2$State=="Victoria"] <- 1
Koala2$Vic[Koala2$State!="Victoria"] <- 0
# change class of Vic column to numeric...
Koala2$Vic <- as.numeric(Koala2$Vic)

# optionally output selected columns to check result...
# head(Koala2[,c(12,14:16)],20)

Koala2.vic <- aggregate(data = Koala2, Vic ~ Species,
        function(Vic) sum(Vic))

# Number of unique States (including blank) by species
### better if blanks can be excluded ###
Koala2.state <- aggregate(data = Koala2, State ~ Species,
        function(State) length(unique(State)))

# number of unique IBRA7 regions by species
### better if blanks can be excluded ###
Koala2.IBRA7 <- aggregate(data = Koala2, IBRA7 ~ Species,
        function(IBRA7) length(unique(IBRA7)))

# number of different Subspecies (including blank) by species
### better if blanks can be excluded ###
Koala2.subsp <- aggregate(data = Koala2, Subspecies ~ Species,
        function(Subspecies) length(unique(Subspecies)))


### better to combine all summary info into one dataframe ###
### using cbind() How to insure order is preserved? ###

## work around: write individual files and ##
## combine in Excel using vlookup ##
write_csv(Koala2.recs,"koala2_recs.csv")
write_csv(Koala2.sp,"koala2_sp.csv")
write_csv(Koala2.vic,"koala2_Vic.csv")
write_csv(Koala2.state,"koala2_states.csv")
write_csv(Koala2.IBRA7,"koala2_IBRA7.csv")
write_csv(Koala2.subsp,"koala2_subspecies.csv")

### also better: create another new column for combined summary file
###  and calculate % of unique records that are for Vic
## work around: do this in Excel
