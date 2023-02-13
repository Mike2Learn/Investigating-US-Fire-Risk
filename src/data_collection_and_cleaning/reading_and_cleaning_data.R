#' Script to read and load in all the data, then create model dataframe

#### Reading data from database ------------------------------------------------
if (read_data_from_db) {
    db_con <- connect_to_db()
}

# tidycensus::fips_codes
fips_codes_raw <- if (read_data_from_db) {
    RMySQL::dbReadTable(db_con, "fips_codes")
} else {
    read_csv("data/fips_codes.csv",
             col_names = TRUE,
             list(
                 state_code = col_integer(),
                 county_code = col_integer()
             ))
}

state_to_state_name <- fips_codes_raw %>%
    as_tibble() %>%
    select(state, state_name) %>%
    distinct() %>%
    mutate(lowercase_state_name = str_to_lower(state_name)) %>%
    when(
        SELECTED_STATES == "ALL" ~ (.),
        TRUE ~ (.) %>%
            filter(state %in% SELECTED_STATES)
    )


# maps::map_data("county")
county_locs_raw <- if (read_data_from_db) {
    RMySQL::dbSendQuery(db_con,
                        str_c("SELECT * FROM county_locs WHERE region IN ('",
                              str_c(state_to_state_name$lowercase_state_name,
                                    collapse = "','"),
                              "')")) %>%
    RMySQL::dbFetch(n = -1)
} else {
    read_csv("data/county_locs.csv",
             col_names = TRUE,
             list(
                 group = col_integer(),
                 order = col_integer()
             )) %>%
        filter(region %in% state_to_state_name$lowercase_state_name)
}

# maps::map_data("state")
state_locs_raw <- if (read_data_from_db) {
    RMySQL::dbSendQuery(db_con,
                        str_c("SELECT * FROM state_locs WHERE region IN ('",
                              str_c(state_to_state_name$lowercase_state_name,
                                    collapse = "','"),
                              "')")) %>%
    RMySQL::dbFetch(n = -1)
} else {
    read_csv("data/state_locs.csv",
             na = "") %>% # "NA" is North America in `subregion` column
        filter(region %in% state_to_state_name$lowercase_state_name)
}

# https://en.wikipedia.org/wiki/List_of_United_States_counties_by_per_capita_income
wiki_county_data_raw <- if (read_data_from_db) {
    RMySQL::dbSendQuery(db_con,
                        str_c("SELECT * FROM wiki_county_data WHERE state_federal_district_or_territory IN ('",
                              str_c(str_replace(state_to_state_name$state_name,
                                                "^District of Columbia$",
                                                "Washington, DC"),
                                    collapse = "','"),
                              "')")) %>%
    RMySQL::dbFetch(n = -1)
} else {
    read_csv("data/wiki_county_data.csv",
             col_names = TRUE,
             list(
                 per_capita_income = col_integer(),
                 median_household_income = col_integer(),
                 median_family_income = col_integer(),
                 population = col_integer(),
                 number_of_households = col_integer()
             )) %>%
        filter(state_federal_district_or_territory %in%
                   str_replace(state_to_state_name$state_name,
                               "^District of Columbia$",
                               "Washington, DC"))
}

# https://www.kaggle.com/datasets/rtatman/188-million-us-wildfires?resource=download
fires_small_raw <- readRDS("data/fires_small_92_15.rds")

if (read_data_from_db) {
    RMySQL::dbDisconnect(db_con)
}

#### Cleaning state locations data ---------------------------------------------
state_locs <- state_locs_raw %>%
    as_tibble()

#### Cleaning county locations data --------------------------------------------
county_locs <- county_locs_raw %>%
    as_tibble()

#### Cleaning Wikipedia county data --------------------------------------------
wiki_county_data <- wiki_county_data_raw %>%
    as_tibble() %>%
    rename(county = county_or_county_equivalent,
           state = state_federal_district_or_territory) %>%
    
    # manual renaming of counties so that future joins work
    mutate(state = ifelse(state == "Washington, DC", "District of Columbia", state),
           county = ifelse(str_detect(county, "County$"),
                           county,
                           str_c(county, " County")),
           county =
               case_when(
                   state == "Louisiana" & county == "DeSoto County" ~ "De Soto County",
                   state == "Illinois" & county == "DeWitt County" ~ "De Witt County",
                   state == "New Mexico" & str_detect(county, "Ana County$") ~ "Dona Ana County",
                   state == "Kentucky" & county == "LaRue County" ~ "Larue County",
                   state == "District of Columbia" ~ "District of Columbia",
                   state == "South Dakota" & county == "Oglala Lakota County" ~ "Shannon County",
                   TRUE ~ county,
               )) %>%
    filter(!(state %in% c("Alaska", "Hawaii")))

#### Cleaning FIPS code data ---------------------------------------------------
fips_codes <- fips_codes_raw %>%
    as_tibble() %>%
    mutate(county_state = str_c(county, state_name, sep = ", "),
           
           # converting state_code and county_code to string with leading 0's
           state_code =
               str_replace_all(
                   format(state_code, width = 2),
                   " ", "0"),
           
           county_code =
               str_replace_all(
                   format(county_code, width = 3),
                   " ", "0"),
           
           # Creating fips identifier for each state-county combination
           geoid = str_c(state_code, county_code))

#### Cleaning fire data --------------------------------------------------------
fires_small <- fires_small_raw %>%
    filter(!is.na(county), !state %in% c("AK", "HI", "PR")) %>%
    left_join(fips_codes %>%
                  select(state, state_code) %>%
                  distinct(),
              by = "state") %>%
    mutate(geoid = str_c(state_code, fips_code)) %>%
    select(-c(fips_code, county, state_code, shape))



#### Reading and cleaning census data (separated for ease of code) -------------
acs_2010_vars <- tidycensus::load_variables(2010, "sf1", cache = TRUE)

# Selecting variables of interest
acs_2010_vars_of_interest <- acs_2010_vars %>%
    filter((label == "Average household size!!Total" & concept == "AVERAGE HOUSEHOLD SIZE OF OCCUPIED HOUSING UNITS BY TENURE") |
               (label == "Total!!Owner occupied" & concept == "TENURE BY HOUSEHOLD SIZE") |
               (label == "Total!!Renter occupied" & concept == "TENURE") |
               (label == "Total races tallied for householders" & concept == "TOTAL RACES TALLIED FOR HOUSEHOLDERS") |
               (label == "Total!!Two or More Races" & concept == "RACE" & name == "P003008") |
               (label == "Total races tallied" & concept == "RACE (TOTAL RACES TALLIED)") |
               (label == "Total!!Population of one race" & concept == "RACE" & name == "P008002") |
               (label == "Total!!Population of one race!!White alone" & concept == "RACE") |
               (label == "Total!!Male" & concept == "SEX BY AGE" & name == "P012002") |
               (label == "Total!!Female" & concept == "SEX BY AGE" & name == "P012026") |
               (label == "Median age!!Both sexes" & concept == "MEDIAN AGE BY SEX") |
               (label == "Total!!Under 18 years" & concept == "POPULATION IN HOUSEHOLDS BY AGE") |
               (label == "Total!!18 years and over" & concept == "POPULATION IN HOUSEHOLDS BY AGE") |
               (label == "Total!!Family households" & concept == "HOUSEHOLD TYPE") |
               (label == "Average family size!!Total" & concept == "AVERAGE FAMILY SIZE BY AGE") |
               (label == "Total!!Household has three or more generations" & concept == "PRESENCE OF MULTIGENERATIONAL HOUSEHOLDS")) %>%
    pull(name, name = label)

# Loading variables of interest from census
us_county_acs_data_raw <-
    get_decennial(geography = "county",
                  variables = unname(acs_2010_vars_of_interest),
                  year = 2010,
                  geometry = TRUE)

# Making map from census variable names to cleaner versions of these variable names
acs_2010_vars_clean_map <- acs_2010_vars_of_interest %>%
    enframe(value = "variable", name = "desc") %>%
    mutate(desc = str_replace_all(desc, "!!| ", "_"),
           desc = str_to_lower(desc))

# Cleaning and tidying census data
us_county_acs_data <- us_county_acs_data_raw %>%
    
    # Renaming variables to their census name
    left_join(acs_2010_vars_clean_map,
              by = "variable") %>%
    select(-variable) %>%
    
    pivot_wider(id_cols = c("GEOID", "NAME", "geometry"),
                names_from = "desc",
                values_from = "value") %>%
    rename(geoid = GEOID,
           county_state = NAME) %>%
    left_join(fips_codes %>%
                  select(-county_state),
              by = "geoid") %>%
    filter(!(state_name %in% c("Alaska", "Hawaii", "Puerto Rico")),
           !str_detect(county_state, ", Puerto Rico$")) %>%
    select(geoid, state, state_code, state_name, county, county_code,
           total_renter_occupied:total_household_has_three_or_more_generations,
           geometry)



# Creating model dataframe -----------------------------------------------------

# Creating dataset of all information for each continental US county
possible_county_name_endings_regex <-
    "City and Borough|Borough|Municipality|Parish County|City County|City|Parish|County|city"

us_county_data_pre_fix <-
    inner_join(
        us_county_acs_data %>%
            mutate(
                county_stripped =
                    str_trim(
                        str_replace(county, possible_county_name_endings_regex, "")
                    )
            ),
        wiki_county_data %>%
            mutate(
                county_stripped =
                    str_trim(
                        str_replace(county, possible_county_name_endings_regex,  "")
                    )
            ),
        by = c("state_name" =  "state", "county_stripped" = "county_stripped"),
        suffix = c("_acs", "_wiki"))


# Fixing issues that arise in join when there are multiple counties in the same
# state with the same name, one with the ending "City Council" and one with the
# ending "Council"
us_county_data_non_dup_rows <- us_county_data_pre_fix %>%
    group_by(geoid) %>%
    filter(n() == 1) %>%
    ungroup

us_county_data_fix_dup_rows <- us_county_data_pre_fix %>%
    group_by(geoid) %>%
    filter(n() >= 2) %>%
    ungroup %>%
    mutate(county_acs = str_to_title(county_acs),
           county_wiki =
               ifelse(str_detect(county_wiki, "City County$"),
                      str_replace(county_wiki, " County", ""),
                      county_wiki)) %>%
    filter(county_acs == county_wiki)

us_county_data <- bind_rows(if (nrow(us_county_data_non_dup_rows) >= 1) us_county_data_non_dup_rows,
                            if (nrow(us_county_data_fix_dup_rows) >= 1) us_county_data_fix_dup_rows) %>%
    select(-county_wiki) %>%
    rename(county = county_acs) %>%
    arrange(state_code, county_code)


# Joining fire data with data about each county
predictors_pre_eda <-
    c("total_renter_occupied",
      "total_races_tallied_for_householders",
      "average_household_size_total",
      "total_owner_occupied",
      "total_two_or_more_races",
      "total_races_tallied",
      "total_population_of_one_race",
      "total_population_of_one_race_white_alone",
      "total_male",
      "median_age_both_sexes",
      "total_under_18_years",
      "total_18_years_and_over",
      "total_family_households",
      "average_family_size_total",
      "total_household_has_three_or_more_generations",
      "per_capita_income",
      "median_household_income",
      "median_family_income",
      "population",
      "number_of_households")

mod_df_pre_eda <- fires_small %>%
    select(-state) %>%
    left_join(us_county_data, by = "geoid") %>%
    na.omit() %>%
    group_by(geoid) %>%
    summarize(num_fires = n(),
              across(all_of(predictors_pre_eda), mean))
