#' This script contains the packages, options(), and constants needed for this analysis

# Loading in needed packages
library(tidyverse)
library(stats)
library(janitor) # clean_names()
library(skimr) # skim()
library(inspectdf) # visual EDA
library(lubridate) # data functions
library(sf) # sf data objects and functions
library(mapview) # mapview()
library(readxl) # read_excel() # TODO
library(tidycensus) # Census data
library(RMySQL) # connecting to database
library(getPass) # getPass(), so password does not need to be stored
library(performance) # model evaluation
library(skimr) # skim()
library(faraway) # stepwise modeling
library(pls) # principal component regression
library(glmnet) # ridge and lasso regression
library(randomForest) # random forest modeling
library(caret) # cross validation


# Setting clear ggplot theme for map plots
theme_set(theme_bw())

# Vector of selected states among 48 continental US states + "DC" or "ALL"
# Use 2 letter abbreviation for state
# If specifying subset of states, declare, for example, as follows:
# SELECTED_STATES <- c("CA", "AZ", "NV")
# NOTE: there are no fires in the dataset in "DC"
SELECTED_STATES <- "ALL"

# Variable that indicates whether data should be read from the database
# specified in src/environment_setup/helper_funcs.R, or the csv files in data
# folder
read_data_from_db <- TRUE
