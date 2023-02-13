---
title: "Investigating United States Fire Risk"
author: "Michael Hymowitz, Zhenning Zhang, Yiwei Mai, Matt Schneider"
date: "Fall 2022"
---



# Introduction

The goal of this research project is twofold. In terms of modeling and data analysis, one goal is to investigate the relationship between various demographic and socioeconomic county-level data with the preclusivity of fires in each county in the continental United States fires, in order to model which people living in the US are most at risk to fires. A second goal of this project is to work with more advanced data science and engineering tools to gain experience working with them, such as creating and maintaining a database, using APIs, database normalization, git, SQL, web scraping, and Markdown. The leveraged dataset includes fires from 1992-2015.

This research contains US fire data from 1992-2015.

# Structure of git Folder

This git folder is structured as follows:

- The `requirements.txt` file documents the packages needed for this analysis, and the package versions utilized.

The `final-report` subfolder contains a pdf file of the final report of this project.

- The `data` folder contains all the data used in this research. A user can either grab all the `.csv`, `.rds`, and `.sqlite` data files, and run the analysis with local data, or create a database using the `data/db/dump-Stats_506_Final_Proj_DB-202211160103.sql` file. A user must specify in `src/environment_setup/imports_options_constants.R` with the `read_data_from_db` boolean variable whether the data is coming from local files or a database. If the data is coming from a database, that information needs to be specified in `src/environment_setup/helper_funcs.R`. The data files in this folder that are leveraged in this research are as follows:
    - `wiki_county_data.csv`
        - County economic and population data
        - Source: [https://en.wikipedia.org/wiki/List_of_United_States_counties_by_per_capita_income](https://en.wikipedia.org/wiki/List_of_United_States_counties_by_per_capita_income)
    - `state_locs.csv`
        - Longitude and latitude location data of continental US states.
        - Source: `maps::map_data("state")`
    - `county_locs.csv`
        - Longitude and latitude location data of continental US counties.
        - Source: `maps::map_data("county")`
    - `fips_codes.csv`
        - FIPS census codes of continental US counties.
        - Source: `tidycensus::fips_codes`
    - `fires_small_92_15.rds`
        - Fires in continental US fire from 1992-2015.
        - Source: [https://www.kaggle.com/datasets/rtatman/188-million-us-wildfires?resource=download](https://www.kaggle.com/datasets/rtatman/188-million-us-wildfires?resource=download)
            - `Fires` sub-table of this database (full database found in `FPA_FOD_20170508.sqlite`)

- The `notebooks` folder contains `exploratory_data_analysis.Rmd`, which documents the EDA process undertaken in this research.

- The `sample_results` folder contains plots created for this analysis. The `sample_results/eda_plots` subfolder contain plots resulting from exploratory data analysis, and the `sample_results/rf_plots` subfolder contains plots resulting from fitting our selected random forest model.

- The `src` folder contains the bulk of the code for this analysis.
    - The `src/environment_setup` subfolder contains `imports_options_constants.R`, which loads in the needed packages, sets preferred options, and declares global variables, and `helpfer_funcs.R`, which contains helper functions needed in other scripts. In this script, a user can choose to only focus on a subset of contintental US states + DC, or all of the continental US states, as well as whether to read the data from a local database or local files.
    - The `src/data_collection_and_cleaning` subfolder contains `scraping_wiki.R`, which documents how county economic and population data was scraped from [Wikipedia](https://en.wikipedia.org/wiki/List_of_United_States_counties_by_per_capita_income), `scraping_fire_data.R`, which documents how fire data was extracted from [Kaggle](https://www.kaggle.com/datasets/rtatman/188-million-us-wildfires?resource=download), and `reading_and_cleaning_data.R`, which reads in data from the various sources either through a local database or downloaded files, joins the tables together, and cleans them so that EDA can be enacted on this table.
    - The `src/modeling` subfolder contains modeling files. In `linear_model.R`, various linear models are fit, and in `random_forest.R`, random forest models are fit.

- `main.R` sources the scripts needed to reproduce the modeling results of this analysis. Before running this script, be sure global constants are set appropriately in `src/environment_setup/imports_options_constants.R`.

# Results

Due to its superior performance, the AIC subset selection of OLS regression model was selected as the best model.

Results from the random forest model shows that the number of households with three or more generations, the population of people with two or more races, and average family size have the most influence on the number of fires that happened. Some results are quite reasonable. Firstly, larger family size leads to more abundant indoor activities, and this may increase the chance of causing a fire. Then, households with three or more generations naturally have a larger average family size than households with less generations in general, thus more households with three or more generations leads to a bigger chance of causing fires. Extraneous factors could be influencing these features' importance.

