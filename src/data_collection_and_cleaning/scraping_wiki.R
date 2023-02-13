#' This script scrapes https://en.wikipedia.org/wiki/List_of_United_States_counties_by_per_capita_income
#' county table

library(tidyverse)
library(rvest) # scraping functions
library(janitor) # clean_names()

# Scraping the table
wiki_url <- "https://en.wikipedia.org/wiki/List_of_United_States_counties_by_per_capita_income"
wiki_income_data_raw <- wiki_url %>%
    read_html() %>%
    html_element(xpath = '//*[@id="mw-content-text"]/div[1]/table[3]') %>%
    html_table()

# Cleaning the table
wiki_income_data <- wiki_income_data_raw %>%
    filter(str_detect(Rank, "^[:digit:]+$")) %>%
    clean_names() %>%
    rename(per_capita_income = per_capitaincome,
           median_household_income = medianhouseholdincome,
           median_family_income = medianfamilyincome,
           number_of_households = number_ofhouseholds) %>%
    mutate(across(per_capita_income:number_of_households,
                  function(col) as.numeric(str_replace_all(col, "\\$|,", "")))) %>%
    arrange(state_federal_district_or_territory, county_or_county_equivalent) %>%
    select(-rank)

# write_csv(wiki_income_data, "wiki_county_data.csv")
