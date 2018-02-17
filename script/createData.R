# Create MO_DEMOS_JeffCityRegion

## Introduction
## This script creates the shapefile MO_DEMOS_JeffCityRegion

## Dependencies
library(dplyr)
library(ggplot2)
library(here)
library(sf)
library(tidycensus)
library(tigris)

## Create combined census tract object
### download all Missouri tracts
moTracts <- tracts(state = "MO")

### convert to sf object
moTracts <- st_as_sf(moTracts)

### data subsetting
jeffRegion <- filter(moTracts, COUNTYFP == "027" | COUNTYFP == "051")

### data cleaning
jeffRegion %>%
  mutate(SQKM = as.numeric(ALAND)/1000000) %>%
  mutate(COUNTY = ifelse(COUNTYFP == "027", "Callaway", "Cole")) %>%
  select(GEOID, COUNTYFP, COUNTY, NAMELSAD, SQKM) -> jeffRegion

### download census tract data
callaway <- get_acs(geography = "tract",  state = "MO", county = "027", output = "wide",
                         variables = c(totalPop = "B02001_001", white = "B02001_002", black = "B02001_003"))
cole <- get_acs(geography = "tract",  state = "MO", county = "051", output = "wide",
                    variables = c(totalPop = "B02001_001", white = "B02001_002", black = "B02001_003"))

### combine census tract data
jeffDemos <- bind_rows(callaway, cole)

### additional data cleaning
jeffDemos <- select(-Name)

### combine spatial and geometric data
jeffRegion <- left_join(jeffRegion, jeffDemos, by = "GEOID")

### re-project from NAD 1983 to Missouri State Plane East
jeffRegion <- st_transform(jeffRegion, 102697)

### write shapefile
st_write(jeffRegion, here("Shapefile", "MO_DEMOS_JeffCityRegion.shp"), delete_dsn = TRUE)
