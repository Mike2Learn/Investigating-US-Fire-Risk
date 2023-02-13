#' Downloading and cleaning the data from
#' https://www.kaggle.com/datasets/rtatman/188-million-us-wildfires?resource=download
#' Needs to be downloaded from this link and saved in the working directory
#' prior to running this script

library(tidyverse)
library(RSQLite) # database access functions
library(janitor) # clean_names()

# connect to db
# https://www.kaggle.com/datasets/rtatman/188-million-us-wildfires?resource=download
db_con <- dbConnect(drv = RSQLite::SQLite(), dbname = "../../data/FPA_FOD_20170508.sqlite")

# The 'Fires' table is where the data lives
fires <- dbGetQuery(conn = db_con, statement = "SELECT * FROM 'Fires'")
fires <- fires %>%
    as_tibble %>%
    clean_names

# Minor data cleaning
fires <- fires %>%
    mutate(fire_code = str_replace_all(fire_code, "^NA$", NA_character_),
           fire_name = str_replace_all(fire_name, "^NA$", NA_character_))

# Selecting only a subset of the columns, some of which may be useful
fires_small <- fires %>%
    dplyr::select(objectid, fire_year, discovery_date, discovery_doy,
                  discovery_time, stat_cause_descr, cont_date, cont_doy,
                  cont_time, fire_size, fire_size_class, latitude, longitude,
                  state, county, fips_code, fips_name, shape)

# saveRDS(fires_small, "fires_small_92_15.rds")
# write_csv(fires_small %>% dplyr::select(-shape), "us_fires_small_1992_2015.csv")


